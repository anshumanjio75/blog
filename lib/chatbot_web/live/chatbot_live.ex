defmodule ChatbotWeb.ChatbotLive do
  use Phoenix.LiveView, container: {:div, [class: "fixed right-0 bottom-0 mr-4"]}

  alias Phoenix.LiveView.JS

  alias Chatbot.Chatbot
  alias Chatbot.Chatbot.Message, as: Message

  @impl true
  def mount(_params, _session, socket) do
    # For this Chatbot, we are only working with a single conversation
    conversation =
      case Chatbot.list_chatbot_conversations() do
        [conversation | _] ->
          conversation

        _ ->
          {:ok, conversation} = Chatbot.create_conversation()
          conversation
      end

    {
      :ok,
      socket
      |> assign(:conversation, conversation)
      |> assign(:message, %Chatbot.Message{})
      |> assign(:messages, [])
    }
  end

  @impl true
  def handle_info({ChatbotWeb.ChatbotLive.FormComponent, {:saved, message}}, socket) do
    messages = [message | socket.assigns.messages]

    Task.async(fn ->
      Chatbot.generate_image_response(socket.assigns.conversation, messages)
    end)

    Task.async(fn ->
      Chatbot.generate_chat_response(socket.assigns.conversation, messages)
    end)

    {
      :noreply,
      socket
      |> assign(:message, %Chatbot.Message{})
      |> assign(:messages, messages)
    }
  end

  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])

    messages =
      case result do
        {:ok, message} -> [message | socket.assigns.messages]
        _ -> socket.assigns.messages
      end

    {
      :noreply,
      socket
      |> assign(:message, %Chatbot.Message{})
      |> assign(:messages, messages)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-col flex-grow w-full max-w-xl bg-white shadow-xl rounded-t-lg overflow-hidden">
      <div class="flex flex-col flex-grow p-4 overflow-auto max-h-[50vh]">
        <div class="flex w-full mt-2 space-x-3 max-w-xs">
          <img class="flex-shrink-0 h-10 w-10 rounded-full bg-gray-300" src="https://images.unsplash.com/photo-1589254065878-42c9da997008?ixlib=rb-1.2.1&amp;ixid=eyJhcHBfaWQiOjEyMDd9&amp;auto=format&amp;fit=facearea&amp;facepad=2&amp;w=256&amp;h=256&amp;q=80" alt="">
          <div>
            <div class="bg-gray-300 p-3 rounded-r-lg rounded-bl-lg">
              <p class="text-sm">Hi. I am here to answer any questions.</p>
            </div>
            <span class="text-xs text-gray-500 leading-none">Now</span>
          </div>
        </div>
        <%= for message <- Enum.reverse(@messages) do %>
          <div id={"message-#{message.id}"} phx-mounted={JS.dispatch("scrollIntoView", to: "#message-#{message.id}")}>
            <div :if={message.role == "user"} class="flex w-full mt-2 space-x-3 max-w-xs ml-auto justify-end">
              <div>
                <div class="bg-blue-600 text-white p-3 rounded-l-lg rounded-br-lg">
                  <p class="text-sm"><%= message.content %></p>
                </div>
                <span class="text-xs text-gray-500 leading-none">Now</span>
              </div>
              <img class="flex-shrink-0 h-10 w-10 rounded-full bg-gray-300" src="/images/logo.svg" alt="">
            </div>

            <div :if={message.role == "assistant"} class="flex w-full mt-2 space-x-3 max-w-xs">
              <img class="flex-shrink-0 h-10 w-10 rounded-full bg-gray-300" src="https://images.unsplash.com/photo-1589254065878-42c9da997008?ixlib=rb-1.2.1&amp;ixid=eyJhcHBfaWQiOjEyMDd9&amp;auto=format&amp;fit=facearea&amp;facepad=2&amp;w=256&amp;h=256&amp;q=80" alt="">
              <div>
                <div class="bg-gray-300 p-3 rounded-r-lg rounded-bl-lg">
                  <%= case message.content |> String.split(", ") do %>
                    <% arr when is_list(arr) and binary_part(hd(arr), 0, 4) == "http" -> %>
                      <%= arr |> Enum.map(& "<a href='#{&1}'> <img src='#{&1}' alt='#{&1}'> </a>" |> Phoenix.HTML.raw())%>
                    <% _ -> %>
                      <p class="text-sm"><%= message.content %></p>
                  <% end %>
                </div>
                <span class="text-xs text-gray-500 leading-none">Now</span>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <div class="bg-gray-300 p-4">
        <.live_component
          module={ChatbotWeb.ChatbotLive.FormComponent}
          id="new-message"
          conversation={@conversation}
          message={@message}
        />
      </div>
    </div>
    """
  end
end
