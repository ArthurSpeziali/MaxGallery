# MaxGallery - Relatório de Testes

## Testes Criados

Foram criados testes abrangentes para os principais módulos do MaxGallery:

### ✅ Testes Funcionando Corretamente

1. **MaxGallery.EncrypterTest** (`test/max_gallery/encrypter_test.exs`)
   - ✅ 18 testes passando
   - Testa todas as funções de criptografia AES-256-CTR
   - Inclui testes de encrypt/decrypt, streams, hash, random
   - Testes de integração completos

2. **MaxGallery.PhantomTest** (`test/max_gallery/phantom_test.exs`)
   - ✅ 24 testes passando
   - Testa validação de dados binários
   - Testa validação de integridade de criptografia
   - Testes de integração com Context

3. **MaxGallery.Storage.MockTest** (`test/max_gallery/storage/mock_test.exs`)
   - ✅ 32 testes passando
   - Testa todas as operações do Storage Mock
   - Inclui testes de streams, arquivos, isolamento por usuário
   - Testes de integração completos

### ⚠️ Testes com Problemas Identificados

4. **MaxGallery.UtilsTest** (`test/max_gallery/utils_test.exs`)
   - ❌ 10 falhas de 37 testes
   - **Problemas identificados:**
     - Função `swap_id` tentando processar listas em vez de mapas individuais
     - Queries com `nil` causando erros de validação do Ecto
     - Função `zip_valid?` não tratando erro `:enoent`

5. **MaxGallery.ContextTest** (`test/max_gallery/context_test.exs`)
   - ❌ 23 falhas de 41 testes
   - **Problemas identificados:**
     - Mesmo problema do `swap_id` afetando operações de grupo
     - Queries com `nil` em campos `file` causando erros do Ecto
     - Problemas de concorrência com `StaleEntryError`
     - Função `group_insert` retornando `{:ok, nil}` em vez de falhar

6. **MaxGallery.CoreTest** (`test/max_gallery/core_test.exs`)
   - Não executado devido aos problemas encontrados nos outros testes

7. **MaxGallery.GroupDuplicationTest** (`test/max_gallery/group_duplication_test.exs`)
   - Não executado devido aos problemas encontrados

## Principais Problemas Identificados no Código

### 1. Problema na função `swap_id` (CypherApi e GroupApi)

**Localização:** `lib/max_gallery/core/api/cypher_api.ex:14`

```elixir
defp swap_id(querry) do
  {value, new_querry} =
    Map.delete(querry, :id)
    |> Map.pop(:file)

  Map.put(new_querry, :id, value)
end
```

**Problema:** A função está sendo chamada com listas em vez de mapas individuais, causando `BadMapError`.

**Solução sugerida:** Verificar se o parâmetro é uma lista e processar cada item individualmente:

```elixir
defp swap_id(querry) when is_list(querry) do
  Enum.map(querry, &swap_id/1)
end

defp swap_id(querry) when is_map(querry) do
  {value, new_querry} =
    Map.delete(querry, :id)
    |> Map.pop(:file)

  Map.put(new_querry, :id, value)
end
```

### 2. Problema com queries usando `nil` em campos `file`

**Localização:** Várias funções em `GroupApi` e `CypherApi`

**Problema:** Ecto não permite comparação direta com `nil`, requer uso de `is_nil/1`.

**Exemplo de erro:**
```
nil given for `file`. comparison with nil is forbidden as it is unsafe. 
Instead write a query with is_nil/1, for example: is_nil(s.file)
```

**Solução sugerida:** Usar `is_nil/1` nas queries:

```elixir
# Em vez de:
|> where(file: ^id)

# Usar:
|> where([q], q.file == ^id or (is_nil(^id) and is_nil(q.file)))
```

### 3. Problema na função `zip_valid?`

**Localização:** `lib/max_gallery/utils.ex:774`

**Problema:** Não trata o erro `:enoent` quando arquivo não existe.

**Solução sugerida:**
```elixir
def zip_valid?(path) do
  String.to_charlist(path)
  |> :zip.zip_open()
  |> case do
    {:ok, pid} ->
      :zip.zip_close(pid)
      true

    {:error, :einval} ->
      false
      
    {:error, :enoent} ->
      false
  end
end
```

### 4. Problema na função `group_insert`

**Problema:** Retorna `{:ok, nil}` em vez de falhar quando a validação phantom falha.

**Solução sugerida:** Retornar erro explícito quando `insert_line?` retorna `false`.

## Problemas de Duplicação de Groups

Os testes específicos para duplicação de grupos (`group_duplication_test.exs`) foram criados para identificar problemas como:

1. **Duplicação de nomes de grupos** - Verificar se grupos com mesmo nome são permitidos
2. **Integridade referencial** - Verificar se duplicações mantêm hierarquia correta
3. **Criptografia única** - Verificar se duplicações geram novas chaves de criptografia
4. **Referências circulares** - Detectar e prevenir referências circulares em grupos
5. **Consistência do banco** - Verificar se não há registros órfãos após operações

## Recomendações

### Prioridade Alta
1. **Corrigir função `swap_id`** - Problema crítico que afeta muitas operações
2. **Corrigir queries com `nil`** - Problema que impede operações de grupo
3. **Corrigir `zip_valid?`** - Problema simples mas que causa falhas

### Prioridade Média
4. **Revisar lógica de `group_insert`** - Melhorar tratamento de erros
5. **Adicionar tratamento de `StaleEntryError`** - Melhorar robustez em operações concorrentes

### Prioridade Baixa
6. **Executar testes de duplicação** - Após corrigir problemas básicos
7. **Adicionar mais testes de edge cases** - Expandir cobertura de testes

## Estrutura de Testes Criada

```
test/
├── max_gallery/
│   ├── encrypter_test.exs          ✅ (18/18 testes passando)
│   ├── phantom_test.exs            ✅ (24/24 testes passando)
│   ├── utils_test.exs              ❌ (27/37 testes passando)
│   ├── context_test.exs            ❌ (18/41 testes passando)
│   ├── core_test.exs               ⏸️ (não executado)
│   ├── group_duplication_test.exs  ⏸️ (não executado)
│   └── storage/
│       └── mock_test.exs           ✅ (32/32 testes passando)
└── README_TESTS.md                 📋 (este arquivo)
```

## Como Executar os Testes

```bash
# Testes que funcionam:
mix test test/max_gallery/encrypter_test.exs
mix test test/max_gallery/phantom_test.exs
mix test test/max_gallery/storage/mock_test.exs

# Testes com problemas (para debug):
mix test test/max_gallery/utils_test.exs
mix test test/max_gallery/context_test.exs

# Executar todos os testes:
mix test
```

Os testes criados fornecem uma base sólida para identificar e corrigir os problemas no código, especialmente relacionados à duplicação de grupos e outras operações críticas do sistema.