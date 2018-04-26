defmodule AuthEx.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Comeonin.Bcrypt
  alias AuthEx.Auth.User

  schema "users" do
    field :password, :string
    field :username, :string
    field :email, :string

    timestamps()
  end

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :password, :email])
    |> validate_required([:username, :password, :email])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)    
    |> put_pass_hash()
 end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password: Bcrypt.hashpwsalt(password))
  end

  defp put_pass_hash(changeset), do: changeset

end
