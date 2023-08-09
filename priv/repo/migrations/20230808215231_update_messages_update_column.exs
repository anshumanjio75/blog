defmodule Chatbot.Repo.Migrations.UpdateMessagesUpdateColumn do
  use Ecto.Migration

  def change do
    alter table(:chatbot_messages) do
      modify :content, :text
    end
  end
end
