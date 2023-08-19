defmodule Chatbot.Chatbot.OpenaiService do
  alias Chatbot.Chatbot
  # alias Chatbot.Finch, as: Finch

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
    |> IO.inspect(label: "chat")
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
          "content" => "#{messages |> Enum.map_join(", ", fn %{"url" => val} -> "#{val}" end)}",
          "role" => "assistant"
        }

      _ ->
        "{}"
    end
  end


  def download_and_save(conversation) do
    {:ok, %Finch.Response{body: body, status: 200}} =
      request_download_image_from_api("nature")

    Chatbot.create_picture(conversation, hd(conversation.messages), %{photo: body, title: "nature"})

    Chatbot.create_message(conversation, %{content: IO.iodata_to_binary(body)|> Base.encode64(), role: "assistant"})
  end

  def download_image(url, conversation, message) do
    # task =
    #   Task.async(fn ->
    #     {:ok, %HTTPoison.Response{body: body}} =
    #       Task.await(request_download_image(url), 10000)
    #       |> IO.inspect(label: "response")

    #     IO.iodata_to_binary(body)
    #     |> Base.encode64()
    #     |> IO.inspect(label: "data")
    #   end)

    # spawn will not block, so it will attempt to execute next spawn straig away

    # {:ok, %HTTPoison.Response{body: body}} =
    #   request_download_image(url)
    #   |> IO.inspect(label: "response")

    # if true do
    #   # File.mkdir_p!("/tmp")
    #   File.cwd()
    #   |> IO.inspect(label: "dir")
    # end

    #   # File.write!("/tmp/my_image.jpg", body)
    #   # |> IO.inspect(label: "download")
    # _data =
    # IO.iodata_to_binary(body)
    # |> Base.encode64()
    # |> IO.inspect(label: "data")
    # result =
    #   Task.await(task, 10000)
    #   |> IO.inspect(label: "final")

    # case result do
    #   {:error, _} -> url
    #   _ -> result
    # end

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        Chatbot.create_picture(conversation, message, %{photo: body, title: url})

      _ ->
        nil
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
    |> IO.inspect(label: "request")
    |> Finch.request(Chatbot.Finch, receive_timeout: 25_000, pool_timeout: 25_000)
    # HTTPoison.post("https://api.openai.com/v1/chat/completions", body, headers(), options())
  end

  defp request_image(body, _opts) do
    Finch.build(:post, "https://api.openai.com/v1/images/generations", headers(), body)
    |> Finch.request(Chatbot.Finch)
    # HTTPoison.post("https://api.openai.com/v1/images/generations", headers(), body)
  end

  def request_download_image(url) do
    Finch.build(:get, url)
    |> Finch.request(Chatbot.Finch)
  end

  def request_download_image_from_api(category) do
    Finch.build(:get, "https://api.api-ninjas.com/v1/randomimage?category=#{category}", headers_image_api())
    |> Finch.request(Chatbot.Finch)
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{File.read!(".env")}"}
    ]
  end

  defp headers_image_api do
    [
      {"Accept", "image/jpg"},
      {"X-Api-Key", "#{File.read!(".imageapi_key")}"}
    ]
  end

  defp options do
    [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 10000]
  end
end
