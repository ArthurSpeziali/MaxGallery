defmodule MaxGallery.PhatomTest do
    use ExUnit.Case, async: true
    alias MaxGallery.Phantom

    setup do
        {:ok,
            fail_datas: [
                %{
                    id: 1,
                    name: <<255, 158, 19, 17, 46, 116, 120, 116>>,
                    blob: <<94, 246, 95, 187, 77, 179, 64, 2, 5, 226, 234, 185, 40, 33,192, 231, 62>>
                },
                %{
                    id: 2,
                    name: <<60, 248, 94, 32, 46, 116,120, 116>>,
                    blob: <<255, 209, 0, 253, 240, 146, 163, 226, 206, 142, 155, 109,206, 232, 190, 119, 68>>
                },
                %{
                    id: 3,
                    name: <<102, 229, 21, 235, 58, 46, 116, 120, 116>>,
                    blob: <<233, 101, 162, 238, 50, 242>>
                  }],

            sucess_datas: [
                %{
                    id: 1,
                    name: "text1.txt",
                    blob: "Hello dark world\n"
                },
                %{
                    id: 2,
                    name: "text2.txt",
                    blob: "Life or death?\n"
                },
                %{
                    id: 3,
                    name: "text3.txt",
                    blob: "Goog bye good world\n"

                }]
        }
    end


    test "Test the encode_bin/1 function for a sucess package", %{sucess_datas: data} do
        assert ^data = Phantom.encode_bin(data)
    end

    test "Test the encode_bin/1 function for a fail package", %{fail_datas: data} do
        assert "/54TES50eHQ=" = Phantom.encode_bin(data) |> List.first() |> Map.get(:name)
    end
end
