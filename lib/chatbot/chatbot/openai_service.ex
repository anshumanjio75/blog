defmodule Chatbot.Chatbot.OpenaiService do
  defp default_system_prompt do
    """
    You are a chatbot that only answers questions about the programming language C#.
    Answer short with just a 1-3 sentences.
    If the question is about another programming language, make a joke about it.
    If the question is about something else, answer something like:
    "I dont know, its not my cup of tea" or "I have no opinion about that topic".
    """
  end

  def call_chat(prompts, opts \\ []) do
    %{
      "model" => "gpt-3.5-turbo",
      "messages" =>
        Enum.concat(
          [
            %{"role" => "system", "content" => ""}
          ],
          prompts
        ),
      "temperature" => 0.7
    }
    |> Jason.encode!()
    |> request_chat(opts)
    |> parse_response_chat()
  end

  def call_image(prompts, opts \\ []) do
    %{
      "prompt" => prompts |> Enum.reverse() |> hd() |> Map.get("content"),
      "n" => 2,
      "size" => "1024x1024"
    }
    |> Jason.encode!()
    |> request_image(opts)
    |> parse_response_image()
  end

  defp parse_response_chat({:ok, %Finch.Response{body: body}}) do
    messages =
      Jason.decode!(body)
      |> Map.get("choices", [])
      |> Enum.reverse()

    case messages do
      [%{"message" => message} | _] -> message
      _ -> "{}"
    end
  end

  defp parse_response_image({:ok, %Finch.Response{body: body}}) do
    messages =
      Jason.decode!(body)
      |> Map.get("data", [])
      |> Enum.reverse()

    case messages do
      [%{"url" => _url} | _] ->
        %{
          "content" =>
            "#{messages |> Enum.map_join(", ", fn %{"url" => val} -> "#{val}" end)}",
          "role" => "assistant"
        }

      _ ->
        "{}"
    end
  end

  defp parse_response_chat(error) do
    error
  end

  defp parse_response_image(error) do
    error
  end

  defp request_chat(body, _opts) do
    Finch.build(:post, "https://api.openai.com/v1/chat/completions", headers(), body)
    |> Finch.request(Chatbot.Finch)
  end

  defp request_image(body, _opts) do
    Finch.build(:post, "https://api.openai.com/v1/images/generations", headers(), body)
    |> Finch.request(Chatbot.Finch)
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{File.read!(".env")}"}
    ]
  end
end
