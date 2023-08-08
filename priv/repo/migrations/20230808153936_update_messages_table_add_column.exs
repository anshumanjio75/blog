defmodule Chatbot.Repo.Migrations.UpdateMessagesTableAddColumn do
  use Ecto.Migration

  def change do
    alter table(:chatbot_messages) do
      add :content, :string
      add :role, :string
    end
  end
end
