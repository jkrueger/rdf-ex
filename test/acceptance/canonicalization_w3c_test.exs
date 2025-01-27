defmodule RDF.Canonicalization.W3C.Test do
  @moduledoc """
  The RDF Dataset Canonicalization Test Suite.

  from <https://github.com/w3c/rdf-canon>
  """

  use ExUnit.Case, async: false
  use EarlFormatter, test_suite: :rdf_canon

  alias RDF.{TestSuite, NQuads, Canonicalization}
  alias TestSuite.NS.RDFC

  @path RDF.TestData.path("rdf-canon-tests")
  @base "https://github.com/w3c/rdf-canon/tests/"
  @manifest TestSuite.manifest_path(@path, "manifest-urdna2015.ttl")
            |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFC.Urdna2015EvalTest)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      file_url = to_string(TestSuite.test_input_file(test_case))
      input = test_case_file(test_case, &TestSuite.test_input_file/1)
      result = test_case_file(test_case, &TestSuite.test_output_file/1)

      assert NQuads.read_file!(input, base: file_url)
             |> Canonicalization.canonicalize() ==
               NQuads.read_file!(result)
    end
  end)

  defp test_case_file(test_case, file_type) do
    Path.join(
      @path,
      test_case
      |> file_type.()
      |> to_string()
      |> String.trim_leading(@base)
    )
  end
end
