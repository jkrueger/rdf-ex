defmodule RDF.DatasetTest do
  use RDF.Test.Case

  doctest RDF.Dataset


  describe "new" do
    test "creating an empty unnamed dataset" do
      assert unnamed_dataset?(unnamed_dataset())
    end

    test "creating an empty dataset with a proper dataset name" do
      refute unnamed_dataset?(named_dataset())
      assert named_dataset?(named_dataset())
    end

    test "creating an empty dataset with a coercible dataset name" do
      assert named_dataset("http://example.com/DatasetName")
             |> named_dataset?(iri("http://example.com/DatasetName"))
      assert named_dataset(EX.Foo) |> named_dataset?(iri(EX.Foo))
    end

    test "creating an unnamed dataset with an initial triple" do
      ds = Dataset.new({EX.Subject, EX.predicate, EX.Object})
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed dataset with an initial quad" do
      ds = Dataset.new({EX.Subject, EX.predicate, EX.Object, EX.GraphName})
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds,
        {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "creating a named dataset with an initial triple" do
      ds = Dataset.new(EX.DatasetName, {EX.Subject, EX.predicate, EX.Object})
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named dataset with an initial quad" do
      ds = Dataset.new(EX.DatasetName, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "creating an unnamed dataset with a list of initial statements" do
      ds = Dataset.new([
              {EX.Subject1, EX.predicate1, EX.Object1},
              {EX.Subject2, EX.predicate2, EX.Object2, EX.GraphName},
              {EX.Subject3, EX.predicate3, EX.Object3, nil}
           ])
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, nil})
    end

    test "creating a named dataset with a list of initial statements" do
      ds = Dataset.new(EX.DatasetName, [
              {EX.Subject, EX.predicate1, EX.Object1},
              {EX.Subject, EX.predicate2, EX.Object2, EX.GraphName},
              {EX.Subject, EX.predicate3, EX.Object3, nil}
           ])
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2, EX.Object2, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate3, EX.Object3, nil})
    end

    test "creating a named dataset with an initial description" do
      ds = Dataset.new(EX.DatasetName, Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed dataset with an initial description" do
      ds = Dataset.new(Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named dataset with an inital graph" do
      ds = Dataset.new(EX.DatasetName, Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})

      ds = Dataset.new(EX.DatasetName, Graph.new(EX.GraphName, {EX.Subject, EX.predicate, EX.Object}))
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), iri(EX.GraphName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "creating an unnamed dataset with an inital graph" do
      ds = Dataset.new(Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_dataset?(ds)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})

      ds = Dataset.new(Graph.new(EX.GraphName, {EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_dataset?(ds)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), iri(EX.GraphName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end
  end

  describe "add" do
    test "a proper triple is added to the default graph" do
      assert Dataset.add(dataset(), {iri(EX.Subject), EX.predicate, iri(EX.Object)})
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a proper quad is added to the specified graph" do
      ds = Dataset.add(dataset(), {iri(EX.Subject), EX.predicate, iri(EX.Object), iri(EX.Graph)})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, iri(EX.Graph)})
    end

    test "a proper quad with nil context is added to the default graph" do
      ds = Dataset.add(dataset(), {iri(EX.Subject), EX.predicate, iri(EX.Object), nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "a coercible triple" do
      assert Dataset.add(dataset(),
          {"http://example.com/Subject", EX.predicate, EX.Object})
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a coercible quad" do
      assert Dataset.add(dataset(),
          {"http://example.com/Subject", EX.predicate, EX.Object, "http://example.com/GraphName"})
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "a quad and an overwriting graph context " do
      assert Dataset.add(dataset(), {EX.Subject, EX.predicate, EX.Object, EX.Graph}, EX.Other)
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object, EX.Other})
      assert Dataset.add(dataset(), {EX.Subject, EX.predicate, EX.Object, EX.Graph}, nil)
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "statements with multiple objects" do
      ds = Dataset.add(dataset(), {EX.Subject1, EX.predicate1, [EX.Object1, EX.Object2]})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object2})

      ds = Dataset.add(dataset(), {EX.Subject1, EX.predicate1, [EX.Object1, EX.Object2], EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object2, EX.GraphName})
    end

    test "a list of triples without specification of the default context" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "a list of triples with specification of the default context" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ], EX.Graph)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, EX.Graph})

      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ], nil)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, nil})
    end

    test "a list of quads without specification of the default context" do
      ds = Dataset.add(dataset(), [
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph1},
        {EX.Subject, EX.predicate2, EX.Object2, nil},
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph2}
      ])
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, EX.Graph1})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2, EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, EX.Graph2})
    end

    test "a list of quads with specification of the default context" do
      ds = Dataset.add(dataset(), [
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph1},
        {EX.Subject, EX.predicate2, EX.Object2, nil},
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph2}
      ], EX.Graph)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2, EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, EX.Graph})

      ds = Dataset.add(dataset(), [
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph1},
        {EX.Subject, EX.predicate2, EX.Object2, nil},
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph2}
      ], nil)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2, EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, nil})
    end

    test "a list of mixed triples and quads" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.GraphName},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, nil})
    end

    test "a Description without specification of the default context" do
      ds = Dataset.add(dataset(), Description.new(EX.Subject1, [
        {EX.predicate1, EX.Object1},
        {EX.predicate2, EX.Object2},
      ]))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

    end

    test "a Description with specification of the default context" do
      ds = Dataset.add(dataset(), Description.new(EX.Subject1, [
        {EX.predicate1, EX.Object1},
        {EX.predicate2, EX.Object2},
      ]), nil)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Description.new({EX.Subject1, EX.predicate3, EX.Object3}), EX.Graph)
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3, EX.Graph})
    end

    test "an unnamed Graph without specification of the default context" do
      ds = Dataset.add(dataset(), Graph.new([
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2, EX.Object3}))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
    end

    test "an unnamed Graph with specification of the default context" do
      ds = Dataset.add(dataset(), Graph.new([
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]), nil)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2, EX.Object3}), nil)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2, EX.Object3}), EX.Graph)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.Graph), iri(EX.Graph))
      assert Enum.count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph})
    end

    test "a named Graph without specification of the default context" do
      ds = Dataset.add(dataset(), Graph.new(EX.Graph1, [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]))
      assert Dataset.graph(ds, EX.Graph1)
      assert named_graph?(Dataset.graph(ds, EX.Graph1), iri(EX.Graph1))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph1})

      ds = Dataset.add(ds, Graph.new(EX.Graph2, {EX.Subject1, EX.predicate2, EX.Object3}))
      assert Dataset.graph(ds, EX.Graph2)
      assert named_graph?(Dataset.graph(ds, EX.Graph2), iri(EX.Graph2))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph2})
    end

    test "a named Graph with specification of the default context" do
      ds = Dataset.add(dataset(), Graph.new(EX.Graph1, [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]), nil)
      refute Dataset.graph(ds, EX.Graph1)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Graph.new(EX.Graph2, {EX.Subject1, EX.predicate2, EX.Object3}), nil)
      refute Dataset.graph(ds, EX.Graph2)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})

      ds = Dataset.add(ds, Graph.new(EX.Graph3, {EX.Subject1, EX.predicate2, EX.Object3}), EX.Graph)
      assert named_graph?(Dataset.graph(ds, EX.Graph), iri(EX.Graph))
      assert Enum.count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph})
    end

    test "an unnamed Dataset" do
      ds = Dataset.add(dataset(), Dataset.new([
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]))
      assert ds.name == nil
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2, EX.Object3}))
      ds = Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2, EX.Object3, EX.Graph}))
      ds = Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2, EX.Object4}), EX.Graph)
      assert ds.name == nil
      assert Enum.count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object4, EX.Graph})
    end

    test "a named Dataset" do
      ds = Dataset.add(named_dataset(), Dataset.new(EX.DS1, [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]))
      assert ds.name == iri(EX.DatasetName)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Dataset.new(EX.DS2, {EX.Subject1, EX.predicate2, EX.Object3}))
      ds = Dataset.add(ds, Dataset.new(EX.DS2, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph}))
      ds = Dataset.add(ds, Dataset.new(EX.DS2, {EX.Subject1, EX.predicate2, EX.Object4}), EX.Graph)
      assert ds.name == iri(EX.DatasetName)
      assert Enum.count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object4, EX.Graph})
    end

    test "a list of Descriptions" do
      ds = Dataset.add(dataset(), [
        Description.new({EX.Subject1, EX.predicate1, EX.Object1}),
        Description.new({EX.Subject2, EX.predicate2, EX.Object2}),
        Description.new({EX.Subject1, EX.predicate3, EX.Object3})
      ])
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3})

      ds = Dataset.add(ds, [
        Description.new({EX.Subject1, EX.predicate1, EX.Object1}),
        Description.new({EX.Subject2, EX.predicate2, EX.Object2}),
        Description.new({EX.Subject1, EX.predicate3, EX.Object3})
      ], EX.Graph)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3})
    end

    test "a list of Graphs" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> RDF.Dataset.add([
            Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, bnode(:foo)}]),
            Graph.new(nil, {EX.S1, EX.P2, EX.O3}),
            Graph.new(EX.Graph, [{EX.S1, EX.P2, EX.O2}, {EX.S2, EX.P2, EX.O2}])
           ])

        assert Enum.count(ds) == 6
        assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
        assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
        assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3})
        assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
        assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O2, EX.Graph})
        assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.Graph})
    end

    test "duplicates are ignored" do
      ds = Dataset.add(dataset(), {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
      assert Dataset.add(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName}) == ds
    end

    test "non-coercible statements elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(dataset(), {"not a IRI", EX.predicate, iri(EX.Object), iri(EX.GraphName)})
      end
      assert_raise RDF.Literal.InvalidError, fn ->
        Dataset.add(dataset(), {EX.Subject, EX.prop, self(), nil})
      end
      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(dataset(), {iri(EX.Subject), EX.predicate, iri(EX.Object), "not a IRI"})
      end
    end
  end

  describe "put" do
    test "a list of statements without specification of the default context" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> RDF.Dataset.put([
              {EX.S1, EX.P2, EX.O3, EX.Graph},
              {EX.S1, EX.P2, bnode(:foo), nil},
              {EX.S2, EX.P2, EX.O3, EX.Graph},
              {EX.S2, EX.P2, EX.O4, EX.Graph}])

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4, EX.Graph})
    end

    test "a list of statements with specification of the default context" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> RDF.Dataset.put([
              {EX.S1, EX.P1, EX.O3, EX.Graph},
              {EX.S1, EX.P2, bnode(:foo), nil},
              {EX.S2, EX.P2, EX.O3, EX.Graph},
              {EX.S2, EX.P2, EX.O4}], nil)

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.Graph})

      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> RDF.Dataset.put([
              {EX.S1, EX.P1, EX.O3},
              {EX.S1, EX.P1, EX.O4, EX.Graph},
              {EX.S1, EX.P2, bnode(:foo), nil},
              {EX.S2, EX.P2, EX.O3, EX.Graph},
              {EX.S2, EX.P2, EX.O4}], EX.Graph)

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4, EX.Graph})
    end

    test "a Description" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> RDF.Dataset.put(Description.new(EX.S1, [{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}]))

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "an unnamed Graph" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> RDF.Dataset.put(Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]))

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "a named Graph" do
      ds = Dataset.new(
            Graph.new(EX.GraphName, [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}]))
        |> RDF.Dataset.put(
            Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]), EX.GraphName)

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.GraphName})
    end

    test "simultaneous use of the different forms to address the default context" do
      ds = RDF.Dataset.put(dataset(), [
            {EX.S, EX.P, EX.O1},
            {EX.S, EX.P, EX.O2, nil}])
      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})
    end
  end


  describe "delete" do
    setup do
      {:ok,
        dataset1: Dataset.new({EX.S1, EX.p1, EX.O1}),
        dataset2: Dataset.new([
            {EX.S1, EX.p1, EX.O1},
            {EX.S2, EX.p2, EX.O2, EX.Graph},
          ]),
        dataset3: Dataset.new([
            {EX.S1, EX.p1, EX.O1},
            {EX.S2, EX.p2, [EX.O1, EX.O2], EX.Graph1},
            {EX.S3, EX.p3, [~B<foo>, ~L"bar"], EX.Graph2},
          ]),
      }
    end

    test "a single statement",
          %{dataset1: dataset1, dataset2: dataset2, dataset3: dataset3} do
      assert Dataset.delete(Dataset.new, {EX.S, EX.p, EX.O}) == Dataset.new
      assert Dataset.delete(dataset1, {EX.S1, EX.p1, EX.O1}) == Dataset.new
      assert Dataset.delete(dataset2, {EX.S2, EX.p2, EX.O2, EX.Graph}) == dataset1
      assert Dataset.delete(dataset2, {EX.S1, EX.p1, EX.O1}) ==
              Dataset.new({EX.S2, EX.p2, EX.O2, EX.Graph})
      assert Dataset.delete(dataset3, {EX.S2, EX.p2, EX.O1, EX.Graph1}) ==
              Dataset.new [
                {EX.S1, EX.p1, EX.O1},
                {EX.S2, EX.p2, EX.O2, EX.Graph1},
                {EX.S3, EX.p3, [~B<foo>, ~L"bar"], EX.Graph2},
              ]
      assert Dataset.delete(dataset3, {EX.S2, EX.p2, [EX.O1, EX.O2], EX.Graph1}) ==
              Dataset.new [
                {EX.S1, EX.p1, EX.O1},
                {EX.S3, EX.p3, [~B<foo>, ~L"bar"], EX.Graph2},
              ]
      assert Dataset.delete(dataset3, {EX.S2, EX.p2, [EX.O1, EX.O2]}, EX.Graph1) ==
              Dataset.new [
                {EX.S1, EX.p1, EX.O1},
                {EX.S3, EX.p3, [~B<foo>, ~L"bar"], EX.Graph2},
              ]
    end

    test "multiple statements with a list of triples",
          %{dataset1: dataset1, dataset2: dataset2, dataset3: dataset3} do
      assert Dataset.delete(dataset1, [{EX.S1, EX.p1, EX.O1},
                                       {EX.S1, EX.p1, EX.O2}]) == Dataset.new
      assert Dataset.delete(dataset2, [{EX.S1, EX.p1, EX.O1},
                                       {EX.S2, EX.p2, EX.O2, EX.Graph}]) == Dataset.new
      assert Dataset.delete(dataset3, [
              {EX.S1, EX.p1, EX.O1},
              {EX.S2, EX.p2, [EX.O1, EX.O2, EX.O3], EX.Graph1},
              {EX.S3, EX.p3, ~B<foo>, EX.Graph2}]) == Dataset.new({EX.S3, EX.p3, ~L"bar", EX.Graph2})
    end

    test "multiple statements with a Description",
          %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete(dataset1, Description.new(EX.S1, EX.p1, EX.O1)) == Dataset.new
      assert Dataset.delete(dataset1, Description.new(EX.S1, EX.p1, EX.O1), EX.Graph) == dataset1
      assert Dataset.delete(dataset2, Description.new(EX.S2, EX.p2, EX.O2), EX.Graph) == dataset1
      assert Dataset.delete(dataset2, Description.new(EX.S1, EX.p1, EX.O1)) ==
              Dataset.new({EX.S2, EX.p2, EX.O2, EX.Graph})
    end

    test "multiple statements with a Graph",
          %{dataset1: dataset1, dataset2: dataset2, dataset3: dataset3} do
      assert Dataset.delete(dataset1, Graph.new({EX.S1, EX.p1, EX.O1})) == Dataset.new
      assert Dataset.delete(dataset2, Graph.new({EX.S1, EX.p1, EX.O1})) ==
              Dataset.new({EX.S2, EX.p2, EX.O2, EX.Graph})
      assert Dataset.delete(dataset2, Graph.new(EX.Graph, {EX.S2, EX.p2, EX.O2})) == dataset1
      assert Dataset.delete(dataset2, Graph.new(EX.Graph, {EX.S2, EX.p2, EX.O2})) == dataset1
      assert Dataset.delete(dataset2, Graph.new({EX.S2, EX.p2, EX.O2}), EX.Graph) == dataset1
      assert Dataset.delete(dataset2, Graph.new({EX.S2, EX.p2, EX.O2}), EX.Graph) == dataset1
      assert Dataset.delete(dataset3, Graph.new([
                {EX.S1, EX.p1, [EX.O1, EX.O2]},
                {EX.S2, EX.p2, EX.O3},
                {EX.S3, EX.p3, ~B<foo>},
              ])) == Dataset.new([
                {EX.S2, EX.p2, [EX.O1, EX.O2], EX.Graph1},
                {EX.S3, EX.p3, [~B<foo>, ~L"bar"], EX.Graph2},
              ])
      assert Dataset.delete(dataset3, Graph.new(EX.Graph2, [
                {EX.S1, EX.p1, [EX.O1, EX.O2]},
                {EX.S2, EX.p2, EX.O3},
                {EX.S3, EX.p3, ~B<foo>},
              ])) == Dataset.new([
                {EX.S1, EX.p1, EX.O1},
                {EX.S2, EX.p2, [EX.O1, EX.O2], EX.Graph1},
                {EX.S3, EX.p3, [~L"bar"], EX.Graph2},
              ])
      assert Dataset.delete(dataset3, Graph.new({EX.S3, EX.p3, ~B<foo>}), EX.Graph2) ==
              Dataset.new([
                {EX.S1, EX.p1, EX.O1},
                {EX.S2, EX.p2, [EX.O1, EX.O2], EX.Graph1},
                {EX.S3, EX.p3, ~L"bar", EX.Graph2},
              ])
    end

    test "multiple statements with a Dataset",
          %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete(dataset1, dataset1) == Dataset.new
      assert Dataset.delete(dataset1, dataset2) == Dataset.new
      assert Dataset.delete(dataset2, dataset1) == Dataset.new({EX.S2, EX.p2, EX.O2, EX.Graph})
    end
  end


  describe "delete_graph" do
    setup do
      {:ok,
        dataset1: Dataset.new({EX.S1, EX.p1, EX.O1}),
        dataset2: Dataset.new([
            {EX.S1, EX.p1, EX.O1},
            {EX.S2, EX.p2, EX.O2, EX.Graph},
          ]),
        dataset3: Dataset.new([
            {EX.S1, EX.p1, EX.O1},
            {EX.S2, EX.p2, EX.O2, EX.Graph1},
            {EX.S3, EX.p3, EX.O3, EX.Graph2},
          ]),
      }
    end

    test "the default graph", %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete_graph(dataset1, nil) == Dataset.new
      assert Dataset.delete_graph(dataset2, nil) == Dataset.new({EX.S2, EX.p2, EX.O2, EX.Graph})
    end

    test "delete_default_graph", %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete_default_graph(dataset1) == Dataset.new
      assert Dataset.delete_default_graph(dataset2) == Dataset.new({EX.S2, EX.p2, EX.O2, EX.Graph})
    end

    test "a single graph", %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete_graph(dataset1, EX.Graph) == dataset1
      assert Dataset.delete_graph(dataset2, EX.Graph) == dataset1
    end

    test "a list of graphs", %{dataset1: dataset1, dataset3: dataset3}  do
      assert Dataset.delete_graph(dataset3, [EX.Graph1, EX.Graph2]) == dataset1
      assert Dataset.delete_graph(dataset3, [EX.Graph1, EX.Graph2, EX.Graph3]) == dataset1
      assert Dataset.delete_graph(dataset3, [EX.Graph1, EX.Graph2, nil]) == Dataset.new
    end
  end


  test "pop" do
    assert Dataset.pop(Dataset.new) == {nil, Dataset.new}

    {quad, dataset} = Dataset.new({EX.S, EX.p, EX.O, EX.Graph}) |> Dataset.pop
    assert quad == {iri(EX.S), iri(EX.p), iri(EX.O), iri(EX.Graph)}
    assert Enum.count(dataset.graphs) == 0

    {{subject, predicate, object, _}, dataset} =
      Dataset.new([{EX.S, EX.p, EX.O, EX.Graph}, {EX.S, EX.p, EX.O}])
      |> Dataset.pop
    assert {subject, predicate, object} == {iri(EX.S), iri(EX.p), iri(EX.O)}
    assert Enum.count(dataset.graphs) == 1

    {{subject, _, _, graph_context}, dataset} =
      Dataset.new([{EX.S, EX.p, EX.O1, EX.Graph}, {EX.S, EX.p, EX.O2, EX.Graph}])
      |> Dataset.pop
    assert subject == iri(EX.S)
    assert graph_context == iri(EX.Graph)
    assert Enum.count(dataset.graphs) == 1
  end


  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Dataset.new EX.foo) == 0
      assert Enum.count(Dataset.new {EX.S, EX.p, EX.O, EX.Graph}) == 1
      assert Enum.count(Dataset.new [{EX.S, EX.p, EX.O1, EX.Graph}, {EX.S, EX.p, EX.O2}]) == 2

      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph},
        {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert Enum.count(ds) == 3
    end

    test "Enum.member?" do
      refute Enum.member?(Dataset.new, {iri(EX.S), EX.p, iri(EX.O), iri(EX.Graph)})
      assert Enum.member?(Dataset.new({EX.S, EX.p, EX.O, EX.Graph}),
                                      {EX.S, EX.p, EX.O, EX.Graph})

      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph},
        {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert Enum.member?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph})
      assert Enum.member?(ds, {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph})
      assert Enum.member?(ds, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "Enum.reduce" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3, EX.Graph}
      ])

      assert ds == Enum.reduce(ds, dataset(),
        fn(statement, acc) -> acc |> Dataset.add(statement) end)
    end
  end

  describe "Collectable protocol" do
    test "with a list of triples" do
      triples = [
          {EX.Subject, EX.predicate1, EX.Object1},
          {EX.Subject, EX.predicate2, EX.Object2},
          {EX.Subject, EX.predicate2, EX.Object2, EX.Graph}
        ]
      assert Enum.into(triples, Dataset.new()) == Dataset.new(triples)
    end

    test "with a list of lists" do
      lists = [
          [EX.Subject, EX.predicate1, EX.Object1],
          [EX.Subject, EX.predicate2, EX.Object2],
          [EX.Subject, EX.predicate2, EX.Object2, EX.Graph]
        ]
      assert Enum.into(lists, Dataset.new()) ==
              Dataset.new(Enum.map(lists, &List.to_tuple/1))
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Dataset.new[EX.Graph] == nil
      assert Dataset.new({EX.S, EX.p, EX.O, EX.Graph})[EX.Graph] ==
              Graph.new(EX.Graph, {EX.S, EX.p, EX.O})
    end
  end

end
