defmodule RDF.Turtle.Decoder do
  @moduledoc false

  use RDF.Serialization.Decoder

  defmodule State do
    defstruct base_uri: nil, namespaces: %{}, bnode_counter: 0

    def add_namespace(%State{namespaces: namespaces} = state, ns, iri) do
      %State{state | namespaces: Map.put(namespaces, ns, iri)}
    end

    def ns(%State{namespaces: namespaces}, prefix) do
      namespaces[prefix]
    end

    def next_bnode(%State{bnode_counter: bnode_counter} = state) do
      {RDF.bnode("b#{bnode_counter}"),
        %State{state | bnode_counter: bnode_counter + 1}}
    end
  end

  def decode(content, opts \\ %{})

  def decode(content, opts) when is_list(opts),
    do: decode(content, Map.new(opts))

  def decode(content, opts) do
    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast}       <- parse(tokens),
         base = Map.get(opts, :base) do
      build_graph(ast, base && RDF.uri(base))
    else
      {:error, {error_line, :turtle_lexer, error_descriptor}, _error_line_again} ->
        {:error, "Turtle scanner error on line #{error_line}: #{inspect error_descriptor}"}
      {:error, {error_line, :turtle_parser, error_descriptor}} ->
        {:error, "Turtle parser error on line #{error_line}: #{inspect error_descriptor}"}
    end
  end

  defp tokenize(content), do: content |> to_charlist |> :turtle_lexer.string

  defp parse([]),     do: {:ok, []}
  defp parse(tokens), do: tokens |> :turtle_parser.parse

  defp build_graph(ast, base) do
    try do
      {graph, _} =
        Enum.reduce ast, {RDF.Graph.new, %State{base_uri: base}}, fn
          {:triples, triples_ast}, {graph, state} ->
            with {statements, state} = triples(triples_ast, state) do
              {RDF.Graph.add(graph, statements), state}
            end

          {:directive, directive_ast}, {graph, state} ->
            {graph, directive(directive_ast, state)}

        end
      {:ok, graph}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp directive({:prefix, {:prefix_ns, _, ns}, iri}, state) do
    if RDF.URI.Helper.absolute_iri?(iri) do
      State.add_namespace(state, ns, iri)
    else
      with absolute_uri = RDF.URI.Helper.absolute_iri(iri, state.base_uri) do
        State.add_namespace(state, ns, URI.to_string(absolute_uri))
      end
    end
  end

  defp directive({:base, uri}, %State{base_uri: base_uri} = state) do
    cond do
      RDF.URI.Helper.absolute_iri?(uri) ->
        %State{state | base_uri: RDF.uri(uri)}
      base_uri != nil ->
        with absolute_uri = RDF.URI.Helper.absolute_iri(uri, base_uri) do
          %State{state | base_uri: absolute_uri}
        end
      true ->
        raise "Could not resolve resolve relative IRI '#{uri}', no base uri provided"
    end
  end


  defp triples({:blankNodePropertyList, _} = ast, state) do
    with {_, statements, state} = resolve_node(ast, [], state) do
      {statements, state}
    end
  end

  defp triples({subject, predications}, state) do
    with {subject, statements, state} = resolve_node(subject, [], state) do
      Enum.reduce predications, {statements, state}, fn {predicate, objects}, {statements, state} ->
        with {predicate, statements, state} = resolve_node(predicate, statements, state) do
          Enum.reduce objects, {statements, state}, fn object, {statements, state} ->
            with {object, statements, state} = resolve_node(object, statements, state) do
              {[{subject, predicate, object} | statements], state}
            end
          end
        end
      end
    end
  end

  defp resolve_node({:prefix_ln, line_number, {prefix, name}}, statements, state) do
    if ns = State.ns(state, prefix) do
      {RDF.uri(ns <> local_name_unescape(name)), statements, state}
    else
      raise "line #{line_number}: undefined prefix #{inspect prefix}"
    end
  end

  defp resolve_node({:prefix_ns, line_number, prefix}, statements, state) do
    if ns = State.ns(state, prefix) do
      {RDF.uri(ns), statements, state}
    else
      raise "line #{line_number}: undefined prefix #{inspect prefix}"
    end
  end

  defp resolve_node({:relative_uri, relative_uri}, _, %State{base_uri: nil}) do
    raise "Could not resolve resolve relative IRI '#{relative_uri}', no base uri provided"
  end

  defp resolve_node({:relative_uri, relative_uri}, statements, state) do
    {RDF.URI.Helper.absolute_iri(relative_uri, state.base_uri), statements, state}
  end

  defp resolve_node({:anon}, statements, state) do
    with {node, state} = State.next_bnode(state) do
      {node, statements, state}
    end
  end

  defp resolve_node({:blankNodePropertyList, property_list}, statements, state) do
    with {subject, state} = State.next_bnode(state),
         {new_statements, state} = triples({subject, property_list}, state) do
      {subject, statements ++ new_statements, state}
    end
  end

  defp resolve_node({{:string_literal_quote, _line, value}, {:datatype, datatype}}, statements, state) do
    with {datatype, statements, state} = resolve_node(datatype, statements, state) do
      {RDF.literal(value, datatype: datatype), statements, state}
    end
  end

  defp resolve_node({:collection, []}, statements, state) do
    {RDF.nil, statements, state}
  end

  defp resolve_node({:collection, elements}, statements, state) do
    with {first_list_node, state} = State.next_bnode(state),
         [first_element | rest_elements] = elements,
         {first_element_node, statements, state} =
           resolve_node(first_element, statements, state),
         first_statement = [{first_list_node, RDF.first, first_element_node}] do
      {last_list_node, statements, state} =
        Enum.reduce rest_elements, {first_list_node, statements ++ first_statement, state},
          fn element, {list_node, statements, state} ->
            with {element_node, statements, state} =
                   resolve_node(element, statements, state),
                 {next_list_node, state} = State.next_bnode(state) do
              {next_list_node, statements ++ [
                  {list_node,      RDF.rest,  next_list_node},
                  {next_list_node, RDF.first, element_node},
                ], state}
            end
          end
      {first_list_node, statements ++ [{last_list_node, RDF.rest, RDF.nil}], state}
    end
  end

  defp resolve_node(node, statements, state), do: {node, statements, state}

  defp local_name_unescape(string),
    do: Macro.unescape_string(string, &local_name_unescape_map(&1))

  @reserved_characters ~c[~.-!$&'()*+,;=/?#@%_]

  defp local_name_unescape_map(e) when e in @reserved_characters, do: e
  defp local_name_unescape_map(_), do: false

end