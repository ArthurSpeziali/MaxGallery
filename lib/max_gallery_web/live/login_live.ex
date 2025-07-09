defmodule MaxGalleryWeb.Live.LoginLive do
    use MaxGalleryWeb, :live_view
    alias MaxGallery.Validate
    alias MaxGallery.Context
    alias MaxGallery.Server.LiveServer


    def mount(%{"action" => action}, _session, socket) do
        action = 
            if action in ~w(login register) do  
                action
            else
                "login"
            end

        counter = 
            if action == "login" do
                "register"
            else
                "login"
            end


        socket = assign(socket,
            action: action,
            counter: counter,
            error_list: []
        )

        {:ok, socket, layout: false}
    end
    def mount(_params, _session, socket) do
        {:ok, 
            push_navigate(socket, to: "/")
        }
    end


    def handle_event("confirm_form", params, socket) do
        action = socket.assigns[:action]
        error_list = []

        response = 
            if action == "login" do
                %{"email" => email, "passwd" => password} = params

                error_list = 
                    case Validate.email(email) do
                        :ok -> error_list

                        {:error, reason} -> [err_email: reason] ++ error_list
                    end

                error_list = 
                    case Validate.passwd(password) do
                        :ok -> error_list

                        {:error, reason} -> [err_passwd: reason] ++ error_list
                    end


                if error_list == [] do
                    {femail, fpassword} = {
                        Validate.input!(email),
                        Validate.input!(password)
                    }
                    

                    case Context.user_validate(femail, fpassword) do
                        {:ok, id} ->
                            LiveServer.put(%{auth_user: id})
                            :ok


                        {:error, "invalid email/passwd"} ->
                            {:error, [err_get: "Password or E-mail is invalid. Try another credentials."] ++ error_list}

                        {:error, "not found"} ->
                            {:error, [err_get: "This User does not exist in our database."] ++ error_list}
                    end
                else
                    {:error, error_list}
                end 
            else
                :register
            end


        if response == :ok do
            {:noreply,
                push_navigate(socket, to: "/user")
            }
        else
            {:noreply,
                assign(socket, error_list: error_list)
            }
        end
    end
end
