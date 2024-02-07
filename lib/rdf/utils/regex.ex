defmodule RDF.Util.Regex do
  @moduledoc """
  Some of the regular expressions in the code base get executed in quote tight
  loops, sometimes millions of times. The elixir code base does a check on every
  run of a comppiled regex, to check if the pcre version of the regex matches the
  version that the local OTP version got compiled against. This check seems to
  be unexpectedly costly (there is acall though to :erlang.system_info/1). It
  seems worth it performance wise to curcumvent elixir here, and call trough to 
  erlang 're' in this case.
  """

  @doc """
  Replaces the elixir regex run function. It only works with compiled regexes,
  and always returns the matched binaries
  """
  @spec run(Regex.t(), binary()) :: nil | [binary]
  def run(%Regex{re_pattern: pattern}, string) do
    case :re.run(string, pattern, [{:capture, :all, :binary}]) do
      {:match, matches} -> matches
      :nomatch -> nil
      :match -> []
    end
  end
end