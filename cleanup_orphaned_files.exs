#!/usr/bin/env elixir

# Script para limpar e reparar arquivos órfãos (registros no banco sem arquivo no S3)
# Execute com: mix run cleanup_orphaned_files.exs

alias MaxGallery.Context
alias MaxGallery.Core.Cypher.Api, as: CypherApi
alias MaxGallery.Storage
require Logger

defmodule OrphanedFilesCleanup do
  def run do
    IO.puts("=== Limpeza de Arquivos Órfãos ===")
    
    # Solicitar dados do usuário
    user_id = IO.gets("Digite o ID do usuário: ") |> String.trim()
    key = IO.gets("Digite a chave de encriptação: ") |> String.trim()
    
    IO.puts("Verificando arquivos órfãos para o usuário: #{user_id}")
    
    case Context.cleanup_orphaned_files(user_id, key) do
      {:ok, count} ->
        IO.puts("✅ Limpeza concluída com sucesso!")
        IO.puts("📊 Total de arquivos órfãos removidos: #{count}")
        
      {:error, "invalid key/user"} ->
        IO.puts("❌ Erro: Chave de encriptação ou usuário inválido")
        
      {:error, reason} ->
        IO.puts("❌ Erro durante a limpeza: #{reason}")
    end
  end
  
  def repair do
    IO.puts("=== Reparo de Arquivos Órfãos ===")
    
    # Solicitar dados do usuário
    user_id = IO.gets("Digite o ID do usuário: ") |> String.trim()
    key = IO.gets("Digite a chave de encriptação: ") |> String.trim()
    
    IO.puts("Tentando reparar arquivos órfãos para o usuário: #{user_id}")
    
    case Context.repair_orphaned_files(user_id, key) do
      {:ok, %{repaired: repaired, failed: failed}} ->
        IO.puts("✅ Reparo concluído!")
        IO.puts("📊 Arquivos reparados: #{repaired}")
        IO.puts("📊 Arquivos que falharam: #{failed}")
        
      {:error, "invalid key/user"} ->
        IO.puts("❌ Erro: Chave de encriptação ou usuário inválido")
        
      {:error, reason} ->
        IO.puts("❌ Erro durante o reparo: #{reason}")
    end
  end
  
  def check_specific_file(user_id, file_id) do
    IO.puts("=== Verificação de Arquivo Específico ===")
    IO.puts("Usuário: #{user_id}")
    IO.puts("Arquivo ID: #{file_id}")
    
    case CypherApi.get(file_id) do
      {:ok, file} ->
        IO.puts("✅ Arquivo encontrado no banco de dados")
        IO.puts("   Nome: #{file.name}")
        IO.puts("   Tamanho: #{file.length} bytes")
        IO.puts("   Extensão: #{file.ext}")
        
        if Storage.exists?(user_id, file_id) do
          IO.puts("✅ Arquivo existe no S3")
        else
          IO.puts("❌ Arquivo NÃO existe no S3 (órfão)")
          
          confirm = IO.gets("Deseja deletar este registro órfão? (s/N): ") |> String.trim() |> String.downcase()
          
          if confirm == "s" do
            case CypherApi.delete(file_id) do
              {:ok, _} ->
                IO.puts("✅ Registro órfão deletado com sucesso")
              {:error, reason} ->
                IO.puts("❌ Erro ao deletar registro: #{reason}")
            end
          else
            IO.puts("Operação cancelada")
          end
        end
        
      {:error, "not found"} ->
        IO.puts("❌ Arquivo não encontrado no banco de dados")
        
      {:error, reason} ->
        IO.puts("❌ Erro ao buscar arquivo: #{reason}")
    end
  end
end

# Verificar se foi passado um arquivo específico como argumento
case System.argv() do
  ["check", user_id, file_id] ->
    OrphanedFilesCleanup.check_specific_file(user_id, file_id)
    
  ["cleanup"] ->
    OrphanedFilesCleanup.run()
    
  ["repair"] ->
    OrphanedFilesCleanup.repair()
    
  _ ->
    IO.puts("Uso:")
    IO.puts("  mix run cleanup_orphaned_files.exs cleanup   # Remove arquivos órfãos")
    IO.puts("  mix run cleanup_orphaned_files.exs repair    # Tenta reparar arquivos órfãos")
    IO.puts("  mix run cleanup_orphaned_files.exs check <user_id> <file_id>")
    IO.puts("")
    IO.puts("Exemplos:")
    IO.puts("  mix run cleanup_orphaned_files.exs cleanup")
    IO.puts("  mix run cleanup_orphaned_files.exs repair")
    IO.puts("  mix run cleanup_orphaned_files.exs check ffee63c4-6422-4a0f-895a-0629535ded7c 26")
end