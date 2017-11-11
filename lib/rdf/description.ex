defmodule RDF.Description do
  @moduledoc """
  A set of RDF triples about the same subject.

  `RDF.Description` implements:

  - Elixirs `Access` behaviour
  - Elixirs `Enumerable` protocol
  - Elixirs `Inspect` protocol
  - the `RDF.Data` protocol
  """

  defstruct subject: nil, predications: %{}

  @behaviour Access

  import RDF.Statement

  @type t :: module

  @doc """
  Creates a new `RDF.Description` about the given subject with optional initial statements.

  When given a list of statements, the first one must contain a subject.
  """
  @spec new(RDF.Statement.coercible_subject) :: RDF.Description.t
  def new(subject)

  def new({subject, predicate, object}),
    do: new(subject) |> add(predicate, object)
  def new([statement | more_statements]),
    do: new(statement) |> add(more_statements)
  def new(%RDF.Description{} = description),
    do: description
  def new(subject),
    do: %RDF.Description{subject: coerce_subject(subject)}

  @doc """
  Creates a new `RDF.Description` about the given subject with optional initial statements.
  """
  def new(subject, {predicate, objects}),
    do: new(subject) |> add(predicate, objects)
  def new(subject, statements) when is_list(statements),
    do: new(subject) |> add(statements)
  def new(subject, %RDF.Description{predications: predications}),
    do: %RDF.Description{new(subject) | predications: predications}
  def new(subject, predications = %{}),
    do: new(subject) |> add(predications)

  @doc """
  Creates a new `RDF.Description` about the given subject with optional initial statements.
  """
  def new(%RDF.Description{} = description, predicate, objects),
    do: RDF.Description.add(description, predicate, objects)
  def new(subject, predicate, objects),
    do: new(subject) |> add(predicate, objects)


  @doc """
  Add objects to a predicate of a `RDF.Description`.

  ## Examples

      iex> RDF.Description.add(RDF.Description.new({EX.S, EX.P1, EX.O1}), EX.P2, EX.O2)
      RDF.Description.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
      iex> RDF.Description.add(RDF.Description.new({EX.S, EX.P, EX.O1}), EX.P, [EX.O2, EX.O3])
      RDF.Description.new([{EX.S, EX.P, EX.O1}, {EX.S, EX.P, EX.O2}, {EX.S, EX.P, EX.O3}])
  """
  def add(description, predicate, objects)

  def add(description, predicate, objects) when is_list(objects) do
    Enum.reduce objects, description, fn (object, description) ->
      add(description, predicate, object)
    end
  end

  def add(%RDF.Description{subject: subject, predications: predications}, predicate, object) do
    with triple_predicate = coerce_predicate(predicate),
         triple_object = coerce_object(object),
         new_predications = Map.update(predications,
           triple_predicate, %{triple_object => nil}, fn objects ->
             Map.put_new(objects, triple_object, nil)
           end) do
      %RDF.Description{subject: subject, predications: new_predications}
    end
  end


  @doc """
  Adds statements to a `RDF.Description`.

  Note: When the statements to be added are given as another `RDF.Description`,
  the subject must not match subject of the description to which the statements
  are added. As opposed to that `RDF.Data.merge/2` will produce a `RDF.Graph`
  containing both descriptions.
  """
  def add(description, statements)

  def add(description, {predicate, object}),
    do: add(description, predicate, object)

  def add(description = %RDF.Description{}, {subject, predicate, object}) do
    if coerce_subject(subject) == description.subject,
      do:   add(description, predicate, object),
      else: description
  end

  def add(description, {subject, predicate, object, _}),
    do: add(description, {subject, predicate, object})

  def add(description, statements) when is_list(statements) do
    Enum.reduce statements, description, fn (statement, description) ->
      add(description, statement)
    end
  end

  def add(%RDF.Description{subject: subject, predications: predications},
          %RDF.Description{predications: other_predications}) do
    merged_predications = Map.merge predications, other_predications,
      fn (_, objects, other_objects) -> Map.merge(objects, other_objects) end
    %RDF.Description{subject: subject, predications: merged_predications}
  end

  def add(description = %RDF.Description{}, predications = %{}) do
    Enum.reduce predications, description, fn ({predicate, objects}, description) ->
      add(description, predicate, objects)
    end
  end


  @doc """
  Puts objects to a predicate of a `RDF.Description`, overwriting all existing objects.

  ## Examples

      iex> RDF.Description.put(RDF.Description.new({EX.S, EX.P, EX.O1}), EX.P, EX.O2)
      RDF.Description.new([{EX.S, EX.P, EX.O2}])
      iex> RDF.Description.put(RDF.Description.new({EX.S, EX.P1, EX.O1}), EX.P2, EX.O2)
      RDF.Description.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}])
  """
  def put(description, predicate, objects)

  def put(%RDF.Description{subject: subject, predications: predications},
          predicate, objects) when is_list(objects) do
    with triple_predicate = coerce_predicate(predicate),
         triple_objects   = Enum.reduce(objects, %{}, fn (object, acc) ->
                              Map.put_new(acc, coerce_object(object), nil) end),
      do: %RDF.Description{subject: subject,
            predications: Map.put(predications, triple_predicate, triple_objects)}
  end

  def put(%RDF.Description{} = description, predicate, object),
    do: put(description, predicate, [object])

  @doc """
  Adds statements to a `RDF.Description` and overwrites all existing statements with already used predicates.

  ## Examples

      iex> RDF.Description.put(RDF.Description.new({EX.S, EX.P, EX.O1}), {EX.P, EX.O2})
      RDF.Description.new([{EX.S, EX.P, EX.O2}])
      iex> RDF.Description.new({EX.S, EX.P1, EX.O1}) |>
      ...>   RDF.Description.put([{EX.P2, EX.O2}, {EX.S, EX.P2, EX.O3}, {EX.P1, EX.O4}])
      RDF.Description.new([{EX.S, EX.P1, EX.O4}, {EX.S, EX.P2, EX.O2}, {EX.S, EX.P2, EX.O3}])
      iex> RDF.Description.new({EX.S, EX.P, EX.O1}) |>
      ...>   RDF.Description.put(RDF.Description.new(EX.S, EX.P, [EX.O1, EX.O2]))
      RDF.Description.new([{EX.S, EX.P, EX.O1}, {EX.S, EX.P, EX.O2}])
      iex> RDF.Description.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}]) |>
      ...>   RDF.Description.put(%{EX.P2 => [EX.O3, EX.O4]})
      RDF.Description.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O3}, {EX.S, EX.P2, EX.O4}])
  """
  def put(description, statements)

  def put(%RDF.Description{} = description, {predicate, object}),
    do: put(description, predicate, object)

  def put(%RDF.Description{} = description, {subject, predicate, object}) do
    if coerce_subject(subject) == description.subject,
      do:   put(description, predicate, object),
      else: description
  end

  def put(description, {subject, predicate, object, _}),
    do: put(description, {subject, predicate, object})

  def put(%RDF.Description{subject: subject} = description, statements) when is_list(statements) do
    statements
    |> Stream.map(fn
         {p, o}           -> {coerce_predicate(p), o}
         {^subject, p, o} -> {coerce_predicate(p), o}
         {s, p, o} ->
            if coerce_subject(s) == subject,
              do: {coerce_predicate(p), o}
         bad -> raise ArgumentError, "#{inspect bad} is not a valid statement"
       end)
    |> Stream.filter(&(&1)) # filter nil values
    |> Enum.group_by(&(elem(&1, 0)), &(elem(&1, 1)))
    |> Enum.reduce(description, fn ({predicate, objects}, description) ->
         put(description, predicate, objects)
       end)
  end

  def put(%RDF.Description{subject: subject, predications: predications},
          %RDF.Description{predications: other_predications}) do
    merged_predications = Map.merge predications, other_predications,
      fn (_, _, other_objects) -> other_objects end
    %RDF.Description{subject: subject, predications: merged_predications}
  end

  def put(description = %RDF.Description{}, predications = %{}) do
    Enum.reduce predications, description, fn ({predicate, objects}, description) ->
      put(description, predicate, objects)
    end
  end


  @doc """
  Deletes statements from a `RDF.Description`.
  """
  def delete(description, predicate, objects)

  def delete(description, predicate, objects) when is_list(objects) do
    Enum.reduce objects, description, fn (object, description) ->
      delete(description, predicate, object)
    end
  end

  def delete(%RDF.Description{subject: subject, predications: predications} = descr, predicate, object) do
    with triple_predicate = coerce_predicate(predicate),
         triple_object    = coerce_object(object) do
      if (objects = predications[triple_predicate]) && Map.has_key?(objects, triple_object) do
        %RDF.Description{
          subject: subject,
          predications:
            if map_size(objects) == 1 do
              Map.delete(predications, triple_predicate)
            else
              Map.update!(predications, triple_predicate, fn objects ->
                 Map.delete(objects, triple_object)
               end)
            end
          }
      else
        descr
      end
    end
  end

  @doc """
  Deletes statements from a `RDF.Description`.

  Note: When the statements to be deleted are given as another `RDF.Description`,
  the subject must not match subject of the description from which the statements
  are deleted. If you want to delete only a matching description subject, you can
  use `RDF.Data.delete/2`.
  """
  def delete(description, statements)

  def delete(desc = %RDF.Description{}, {predicate, object}),
    do: delete(desc, predicate, object)

  def delete(description = %RDF.Description{}, {subject, predicate, object}) do
    if coerce_subject(subject) == description.subject,
      do:   delete(description, predicate, object),
      else: description
  end

  def delete(description, {subject, predicate, object, _}),
    do: delete(description, {subject, predicate, object})

  def delete(description, statements) when is_list(statements) do
    Enum.reduce statements, description, fn (statement, description) ->
      delete(description, statement)
    end
  end

  def delete(description = %RDF.Description{}, other_description = %RDF.Description{}) do
    Enum.reduce other_description, description, fn ({_, predicate, object}, description) ->
      delete(description, predicate, object)
    end
  end

  def delete(description = %RDF.Description{}, predications = %{}) do
    Enum.reduce predications, description, fn ({predicate, objects}, description) ->
      delete(description, predicate, objects)
    end
  end


  @doc """
  Deletes all statements with the given properties.
  """
  def delete_predicates(description, properties)

  def delete_predicates(%RDF.Description{} = description, properties) when is_list(properties) do
    Enum.reduce properties, description, fn (property, description) ->
      delete_predicates(description, property)
    end
  end

  def delete_predicates(%RDF.Description{subject: subject, predications: predications}, property) do
    with property = coerce_predicate(property) do
      %RDF.Description{subject: subject, predications: Map.delete(predications, property)}
    end
  end


  @doc """
  Fetches the objects for the given predicate of a Description.

  When the predicate can not be found `:error` is returned.

  ## Examples

      iex> RDF.Description.fetch(RDF.Description.new({EX.S, EX.p, EX.O}), EX.p)
      {:ok, [RDF.iri(EX.O)]}
      iex> RDF.Description.fetch(RDF.Description.new([{EX.S, EX.P, EX.O1},
      ...>                                            {EX.S, EX.P, EX.O2}]), EX.P)
      {:ok, [RDF.iri(EX.O1), RDF.iri(EX.O2)]}
      iex> RDF.Description.fetch(RDF.Description.new(EX.S), EX.foo)
      :error
  """
  def fetch(%RDF.Description{predications: predications}, predicate) do
    with {:ok, objects} <- Access.fetch(predications, coerce_predicate(predicate)) do
      {:ok, Map.keys(objects)}
    end
  end

  @doc """
  Gets the objects for the given predicate of a Description.

  When the predicate can not be found, the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.get(RDF.Description.new({EX.S, EX.P, EX.O}), EX.P)
      [RDF.iri(EX.O)]
      iex> RDF.Description.get(RDF.Description.new(EX.S), EX.foo)
      nil
      iex> RDF.Description.get(RDF.Description.new(EX.S), EX.foo, :bar)
      :bar
  """
  def get(description = %RDF.Description{}, predicate, default \\ nil) do
    case fetch(description, predicate) do
      {:ok, value} -> value
      :error       -> default
    end
  end

  @doc """
  Gets a single object for the given predicate of a Description.

  When the predicate can not be found, the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.first(RDF.Description.new({EX.S, EX.P, EX.O}), EX.P)
      RDF.iri(EX.O)
      iex> RDF.Description.first(RDF.Description.new(EX.S), EX.foo)
      nil
  """
  def first(description = %RDF.Description{}, predicate) do
    description
    |> get(predicate, [])
    |> List.first
  end

  @doc """
  Gets and updates the objects of the given predicate of a Description, in a single pass.

  Invokes the passed function on the objects of the given predicate; this
  function should return either `{objects_to_return, new_object}` or `:pop`.

  If the passed function returns `{objects_to_return, new_objects}`, the return
  value of `get_and_update` is `{objects_to_return, new_description}` where
  `new_description` is the input `Description` updated with `new_objects` for
  the given predicate.

  If the passed function returns `:pop` the objects for the given predicate are
  removed and a `{removed_objects, new_description}` tuple gets returned.

  ## Examples

      iex> RDF.Description.new({EX.S, EX.P, EX.O}) |>
      ...>   RDF.Description.get_and_update(EX.P, fn current_objects ->
      ...>     {current_objects, EX.NEW}
      ...>   end)
      {[RDF.iri(EX.O)], RDF.Description.new({EX.S, EX.P, EX.NEW})}
      iex> RDF.Description.new([{EX.S, EX.P1, EX.O1}, {EX.S, EX.P2, EX.O2}]) |>
      ...>   RDF.Description.get_and_update(EX.P1, fn _ -> :pop end)
      {[RDF.iri(EX.O1)], RDF.Description.new({EX.S, EX.P2, EX.O2})}
  """
  def get_and_update(description = %RDF.Description{}, predicate, fun) do
    with triple_predicate = coerce_predicate(predicate) do
      case fun.(get(description, triple_predicate)) do
        {objects_to_return, new_objects} ->
          {objects_to_return, put(description, triple_predicate, new_objects)}
        :pop -> pop(description, triple_predicate)
      end
    end
  end


  @doc """
  Pops an arbitrary triple from a `RDF.Description`.
  """
  def pop(description)

  def pop(description = %RDF.Description{predications: predications})
    when predications == %{}, do: {nil, description}

  def pop(%RDF.Description{subject: subject, predications: predications}) do
    # TODO: Find a faster way ...
    predicate = List.first(Map.keys(predications))
    [{object, _}] = Enum.take(objects = predications[predicate], 1)

    popped = if Enum.count(objects) == 1,
      do:   elem(Map.pop(predications, predicate), 1),
      else: elem(pop_in(predications, [predicate, object]), 1)

    {{subject, predicate, object},
       %RDF.Description{subject: subject, predications: popped}}
  end

  @doc """
  Pops the objects of the given predicate of a Description.

  When the predicate can not be found the optionally given default value or `nil` is returned.

  ## Examples

      iex> RDF.Description.pop(RDF.Description.new({EX.S, EX.P, EX.O}), EX.P)
      {[RDF.iri(EX.O)], RDF.Description.new(EX.S)}
      iex> RDF.Description.pop(RDF.Description.new({EX.S, EX.P, EX.O}), EX.Missing)
      {nil, RDF.Description.new({EX.S, EX.P, EX.O})}
  """
  def pop(description = %RDF.Description{subject: subject, predications: predications}, predicate) do
    case Access.pop(predications, coerce_predicate(predicate)) do
      {nil, _} ->
        {nil, description}
      {objects, new_predications} ->
        {Map.keys(objects), %RDF.Description{subject: subject, predications: new_predications}}
    end
  end


  @doc """
  The set of all properties used in the predicates within a `RDF.Description`.

  ## Examples

      iex> RDF.Description.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>          {EX.p2, EX.O2},
      ...>          {EX.p2, EX.O3}]) |>
      ...>   RDF.Description.predicates
      MapSet.new([EX.p1, EX.p2])
  """
  def predicates(%RDF.Description{predications: predications}),
    do: predications |> Map.keys |> MapSet.new

  @doc """
  The set of all resources used in the objects within a `RDF.Description`.

  Note: This function does collect only IRIs and BlankNodes, not Literals.

  ## Examples

      iex> RDF.Description.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>          {EX.p2, EX.O2},
      ...>          {EX.p3, EX.O2},
      ...>          {EX.p4, RDF.bnode(:bnode)},
      ...>          {EX.p3, "foo"}
      ...> ]) |> RDF.Description.objects
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode)])
  """
  def objects(%RDF.Description{} = description),
    do: objects(description, &RDF.resource?/1)

  @doc """
  The set of all resources used in the objects within a `RDF.Description` satisfying the given filter criterion.
  """
  def objects(%RDF.Description{predications: predications}, filter_fn) do
    Enum.reduce predications, MapSet.new, fn ({_, objects}, acc) ->
      objects
      |> Map.keys
      |> Enum.filter(filter_fn)
      |> MapSet.new
      |> MapSet.union(acc)
    end
  end

  @doc """
  The set of all resources used within a `RDF.Description`.

  ## Examples

      iex> RDF.Description.new([
      ...>   {EX.S1, EX.p1, EX.O1},
      ...>          {EX.p2, EX.O2},
      ...>          {EX.p1, EX.O2},
      ...>          {EX.p2, RDF.bnode(:bnode)},
      ...>          {EX.p3, "foo"}
      ...> ]) |> RDF.Description.resources
      MapSet.new([RDF.iri(EX.O1), RDF.iri(EX.O2), RDF.bnode(:bnode), EX.p1, EX.p2, EX.p3])
  """
  def resources(description) do
    description
    |> objects
    |> MapSet.union(predicates(description))
  end

  @doc """
  The list of all triples within a `RDF.Description`.
  """
  def triples(description = %RDF.Description{}), do: Enum.to_list(description)

  defdelegate statements(description), to: RDF.Description, as: :triples


  @doc """
  Returns the number of statements of a `RDF.Description`.
  """
  def count(%RDF.Description{predications: predications}) do
    Enum.reduce predications, 0,
      fn ({_, objects}, count) -> count + Enum.count(objects) end
  end


  @doc """
  Checks if the given statement exists within a `RDF.Description`.
  """
  def include?(description, statement)

  def include?(%RDF.Description{predications: predications},
                {predicate, object}) do
    with triple_predicate = coerce_predicate(predicate),
         triple_object    = coerce_object(object) do
      predications
      |> Map.get(triple_predicate, %{})
      |> Map.has_key?(triple_object)
    end
  end

  def include?(desc = %RDF.Description{subject: desc_subject},
              {subject, predicate, object}) do
    coerce_subject(subject) == desc_subject &&
      include?(desc, {predicate, object})
  end

  def include?(%RDF.Description{}, _), do: false


  @doc """
  Checks if a `RDF.Description` has the given resource as subject.

  ## Examples

        iex> RDF.Description.new(EX.S1, EX.p1, EX.O1) |> RDF.Description.describes?(EX.S1)
        true
        iex> RDF.Description.new(EX.S1, EX.p1, EX.O1) |> RDF.Description.describes?(EX.S2)
        false
  """
  def describes?(%RDF.Description{subject: subject}, other_subject) do
    with other_subject = coerce_subject(other_subject) do
      subject == other_subject
    end
  end


  defimpl Enumerable do
    def member?(desc, triple),  do: {:ok, RDF.Description.include?(desc, triple)}
    def count(desc),            do: {:ok, RDF.Description.count(desc)}

    def reduce(%RDF.Description{predications: predications}, {:cont, acc}, _fun)
      when map_size(predications) == 0, do: {:done, acc}

    def reduce(description = %RDF.Description{}, {:cont, acc}, fun) do
      {triple, rest} = RDF.Description.pop(description)
      reduce(rest, fun.(triple, acc), fun)
    end

    def reduce(_,       {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(description = %RDF.Description{}, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(description, &1, fun)}
    end
  end


  defimpl Collectable do
    def into(original) do
      collector_fun = fn
        description, {:cont, list} when is_list(list)
                                   -> RDF.Description.add(description, List.to_tuple(list))
        description, {:cont, elem} -> RDF.Description.add(description, elem)
        description, :done         -> description
        _description, :halt        -> :ok
      end

      {original, collector_fun}
    end
  end

end
