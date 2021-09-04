defmodule RDF.Star.Statement do
  @moduledoc """
  Helper functions for RDF-star statements.

  An RDF-star statement is either a `RDF.Star.Triple` or a `RDF.Star.Quad`.
  """

  alias RDF.Star.{Triple, Quad}
  alias RDF.PropertyMap

  @type subject :: RDF.Statement.subject() | Triple.t()
  @type predicate :: RDF.Statement.predicate()
  @type object :: RDF.Statement.object() | Triple.t()
  @type graph_name :: RDF.Statement.graph_name()

  @type coercible_subject :: RDF.Statement.coercible_subject() | Triple.t()
  @type coercible_predicate :: RDF.Statement.coercible_predicate()
  @type coercible_object :: RDF.Statement.coercible_object() | Triple.t()
  @type coercible_graph_name :: RDF.Statement.coercible_graph_name()

  @type t :: Triple.t() | Quad.t()
  @type coercible_t ::
          {coercible_subject(), coercible_predicate(), coercible_object(), coercible_graph_name()}
          | {coercible_subject(), coercible_predicate(), coercible_object()}

  @doc """
  Creates a `RDF.Star.Triple` or `RDF.Star.Quad` with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  Note: The `RDF.statement` function is a shortcut to this function.

  ## Examples

      iex> RDF.Star.Statement.new({EX.S, EX.p, 42})
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42)}

      iex> RDF.Star.Statement.new({EX.S, EX.p, 42, EX.Graph})
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}

      iex> RDF.Star.Statement.new({EX.S, :p, 42, EX.Graph}, RDF.PropertyMap.new(p: EX.p))
      {RDF.iri("http://example.com/S"), RDF.iri("http://example.com/p"), RDF.literal(42), RDF.iri("http://example.com/Graph")}
  """
  def new(tuple, property_map \\ nil)
  def new({_, _, _} = tuple, property_map), do: Triple.new(tuple, property_map)
  def new({_, _, _, _} = tuple, property_map), do: Quad.new(tuple, property_map)

  defdelegate new(s, p, o), to: Triple, as: :new
  defdelegate new(s, p, o, g), to: Quad, as: :new

  @doc """
  Creates a `RDF.Star.Statement` tuple with proper RDF values.

  An error is raised when the given elements are not coercible to RDF values.

  ## Examples

      iex> RDF.Star.Statement.coerce {"http://example.com/S", "http://example.com/p", 42}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42)}
      iex> RDF.Star.Statement.coerce {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      {~I<http://example.com/S>, ~I<http://example.com/p>, RDF.literal(42), ~I<http://example.com/Graph>}
  """
  @spec coerce(coercible_t(), PropertyMap.t() | nil) :: Triple.t() | Quad.t()
  def coerce(statement, property_map \\ nil)
  def coerce({_, _, _} = triple, property_map), do: Triple.new(triple, property_map)
  def coerce({_, _, _, _} = quad, property_map), do: Quad.new(quad, property_map)

  @doc false
  @spec coerce_subject(coercible_subject, PropertyMap.t() | nil) :: subject
  def coerce_subject(subject, property_map \\ nil)
  def coerce_subject({_, _, _} = triple, property_map), do: Triple.new(triple, property_map)
  def coerce_subject(subject, _), do: RDF.Statement.coerce_subject(subject)

  @doc false
  @spec coerce_predicate(coercible_predicate) :: predicate
  def coerce_predicate(iri), do: RDF.Statement.coerce_predicate(iri)

  @doc false
  @spec coerce_predicate(coercible_predicate, PropertyMap.t()) :: predicate
  def coerce_predicate(term, context), do: RDF.Statement.coerce_predicate(term, context)

  @doc false
  @spec coerce_object(coercible_object, PropertyMap.t() | nil) :: object
  def coerce_object(object, property_map \\ nil)
  def coerce_object({_, _, _} = triple, property_map), do: Triple.new(triple, property_map)
  def coerce_object(object, _), do: RDF.Statement.coerce_object(object)

  @doc false
  @spec coerce_graph_name(coercible_graph_name) :: graph_name
  def coerce_graph_name(iri), do: RDF.Statement.coerce_graph_name(iri)

  @doc """
  Checks if the given tuple is a valid RDF-star statement, i.e. RDF-star triple or quad.

  The elements of a valid RDF-star statement must be RDF terms. On the subject
  position only IRIs, blank nodes and triples allowed, while on the predicate and graph
  context position only IRIs allowed. The object position can be any RDF term or a triple.
  """
  @spec valid?(Triple.t() | Quad.t() | any) :: boolean
  def valid?(tuple)

  def valid?({subject, predicate, object}) do
    valid_subject?(subject) && valid_predicate?(predicate) && valid_object?(object)
  end

  def valid?({subject, predicate, object, graph_name}) do
    valid_subject?(subject) && valid_predicate?(predicate) && valid_object?(object) &&
      valid_graph_name?(graph_name)
  end

  def valid?(_), do: false

  @spec valid_subject?(subject | any) :: boolean
  def valid_subject?({_, _, _} = triple), do: Triple.valid?(triple)
  def valid_subject?(any), do: RDF.Statement.valid_subject?(any)

  @spec valid_predicate?(predicate | any) :: boolean
  def valid_predicate?(any), do: RDF.Statement.valid_predicate?(any)

  @spec valid_object?(object | any) :: boolean
  def valid_object?({_, _, _} = triple), do: Triple.valid?(triple)
  def valid_object?(any), do: RDF.Statement.valid_object?(any)

  @spec valid_graph_name?(graph_name | any) :: boolean
  def valid_graph_name?(any), do: RDF.Statement.valid_graph_name?(any)
end
