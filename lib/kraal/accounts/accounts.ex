defmodule Kraal.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Kraal.Repo

  alias Kraal.Accounts.User
  alias Kraal.Accounts.Roles

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    multi =
      Ecto.Multi.new
      |> Ecto.Multi.insert(:user, user_create_changeset(%User{}, attrs))
      |> Ecto.Multi.run(:activation_token, fn %{user: user} ->
          create_activation_token(user)
        end)
    case Repo.transaction(multi) do
      {:ok, result} ->
        Kraal.Emails.activation_email(result.activation_token, result.user)
        |> Kraal.Mailer.deliver_now
        {:ok, result.user}
      {:error, _elem, changeset, %{}} ->
        {:error, changeset}
    end
  end

  def activate_user(activation_token_id, user_id) do

  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> user_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    user_changeset(user, %{})
  end

  defp user_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_embed(:roles)
    |> validate_required([])
  end

  defp user_create_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email])
    |> put_embed(:roles, Roles.changeset(%Roles{}, attrs))
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  alias Kraal.Accounts.ActivationToken

  @doc """
  Returns the list of activation_tokens.

  ## Examples

      iex> list_activation_tokens()
      [%ActivationToken{}, ...]

  """
  def list_activation_tokens do
    Repo.all(ActivationToken)
  end

  @doc """
  Gets a single activation_token.

  Raises `Ecto.NoResultsError` if the Activation token does not exist.

  ## Examples

      iex> get_activation_token!(123)
      %ActivationToken{}

      iex> get_activation_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_activation_token!(id), do: Repo.get!(ActivationToken, id)

  @doc """
  Creates a activation_token.

  ## Examples

      iex> create_activation_token(%{field: value})
      {:ok, %ActivationToken{}}

      iex> create_activation_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_activation_token(%Kraal.Accounts.User{} = user) do
    %ActivationToken{}
    |> activation_token_changeset(%{})
    |> put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a activation_token.

  ## Examples

      iex> update_activation_token(activation_token, %{field: new_value})
      {:ok, %ActivationToken{}}

      iex> update_activation_token(activation_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_activation_token(%ActivationToken{} = activation_token, attrs) do
    activation_token
    |> activation_token_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ActivationToken.

  ## Examples

      iex> delete_activation_token(activation_token)
      {:ok, %ActivationToken{}}

      iex> delete_activation_token(activation_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_activation_token(%ActivationToken{} = activation_token) do
    Repo.delete(activation_token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking activation_token changes.

  ## Examples

      iex> change_activation_token(activation_token)
      %Ecto.Changeset{source: %ActivationToken{}}

  """
  def change_activation_token(%ActivationToken{} = activation_token) do
    activation_token_changeset(activation_token, %{})
  end

  defp activation_token_changeset(%ActivationToken{} = activation_token, attrs) do
    activation_token
    |> cast(attrs, [])
  end
end