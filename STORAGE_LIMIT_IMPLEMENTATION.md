# Sistema de Limite de Armazenamento por Usuário - MaxGallery

## 🎯 **Funcionalidades Implementadas**

### 1. **Função de Cálculo de Tamanho** (`Utils.user_size/1`)
```elixir
# Calcula o tamanho total usado pelo usuário em GB
def user_size(user) do
  {:ok, all_files} = CypherApi.all(user)
  
  total_bytes = 
    all_files
    |> Enum.map(& &1.length)
    |> Enum.sum()
  
  # Convert bytes to GB (1 GB = 1024^3 bytes)
  total_bytes / (1024 * 1024 * 1024)
end
```

### 2. **Variável de Limite** (`Variables.max_size_user/0`)
```elixir
## 5GB per user limit
@max_size_user 5.0

def max_size_user, do: @max_size_user
```

### 3. **Verificação de Limite no Backend** (`Context.check_size_limit/2`)
```elixir
defp check_size_limit(user, new_file_size) do
  current_size_gb = Utils.user_size(user)
  new_file_size_gb = new_file_size / (1024 * 1024 * 1024)
  total_size_gb = current_size_gb + new_file_size_gb
  
  if total_size_gb <= Variables.max_size_user() do
    :ok
  else
    {:error, "storage_limit_exceeded"}
  end
end
```

### 4. **Bloqueio no Upload** (`Context.cypher_insert/4`)
- Verificação integrada na função de inserção
- Retorna erro específico quando limite é excedido
- Bloqueia upload antes de processar o arquivo

### 5. **Interface do ImportLive**
- **Cálculo em tempo real** do uso atual vs limite
- **Mensagem de aviso** quando limite é excedido
- **Desabilitação** de botões e campos quando necessário

## 🔧 **Implementação Técnica**

### **Backend (Context.ex)**
```elixir
with true <- Phantom.insert_line?(user, key),
     {:ok, {blob_iv, blob}} <- Encrypter.file(:encrypt, path, key),
     {:ok, {msg_iv, msg}} <- Encrypter.encrypt(Phantom.get_text(), key),
     {:ok, _querry} <- UserApi.exists(user),
     :ok <- check_size_limit(user, byte_size(blob)),  # ✅ NOVA VERIFICAÇÃO
     {:ok, querry} <- CypherApi.insert(%{...}) do
  {:ok, querry.id}
else
  {:error, "storage_limit_exceeded"} ->
    {:error, "storage_limit_exceeded"}  # ✅ ERRO ESPECÍFICO
  # ... outros erros
end
```

### **Frontend (ImportLive.ex)**
```elixir
def mount(params, %{"auth_key" => key, "user_auth" => user}, socket) do
  # Calculate current user storage
  current_size_gb = Utils.user_size(user)
  max_size_gb = Variables.max_size_user()
  storage_exceeded = current_size_gb >= max_size_gb

  socket = assign(socket,
    current_size_gb: current_size_gb,
    max_size_gb: max_size_gb,
    storage_exceeded: storage_exceeded
  )
end
```

### **Template (import_live.html.heex)**
```heex
<%= if @storage_exceeded do %>
  <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
    <strong class="font-bold">Storage Limit Exceeded!</strong>
    <span class="block sm:inline">
      You have exceeded your storage limit of <%= Float.round(@max_size_gb, 2) %> GB. 
      Current usage: <%= Float.round(@current_size_gb, 2) %> GB.
      Please delete some files before uploading new ones.
    </span>
  </div>
<% end %>

<button disabled={@storage_exceeded} class={...}>
  Send
</button>
```

## 🎨 **Interface do Usuário**

### **Quando Limite NÃO é Excedido:**
- ✅ Botões habilitados
- ✅ Upload funciona normalmente
- ✅ Interface padrão

### **Quando Limite É Excedido:**
- ❌ **Mensagem de erro** em inglês
- ❌ **Botão "Send" desabilitado** (cinza)
- ❌ **Campo de upload desabilitado** (cinza)
- ❌ **Upload bloqueado** no backend

### **Mensagem Exibida:**
```
🚨 Storage Limit Exceeded!
You have exceeded your storage limit of 5.00 GB. 
Current usage: 5.23 GB.
Please delete some files before uploading new ones.
```

## 📊 **Configuração**

### **Limite Atual:**
- **5.0 GB** por usuário (configurável em `Variables.ex`)

### **Para Alterar o Limite:**
```elixir
# Em lib/max_gallery/variables.ex
@max_size_user 10.0  # Alterar para 10GB, por exemplo
```

## 🧪 **Testes Implementados**

### **Testes de Cálculo de Tamanho:**
- ✅ Usuário sem arquivos retorna 0.0 GB
- ✅ Cálculo correto para usuários com arquivos
- ✅ Soma precisa de múltiplos arquivos

### **Testes de Limite:**
- ✅ Upload permitido quando abaixo do limite
- ✅ Estrutura de verificação de limite
- ✅ Configuração de limite acessível

### **Cobertura de Testes:**
- **67/67 testes passando** (100% de sucesso)
- **6 novos testes** específicos para limite de armazenamento

## 🔄 **Fluxo Completo**

### **1. Usuário Acessa ImportLive:**
```
ImportLive.mount() → Utils.user_size(user) → Calcula uso atual
                  ↓
               Compara com Variables.max_size_user()
                  ↓
            Define @storage_exceeded = true/false
```

### **2. Interface Reativa:**
```
@storage_exceeded = true  → Mostra aviso + desabilita botões
@storage_exceeded = false → Interface normal
```

### **3. Tentativa de Upload:**
```
handle_event("upload") → if storage_exceeded → Bloqueia
                      ↓
                Context.cypher_insert() → check_size_limit()
                      ↓
              {:error, "storage_limit_exceeded"} → Retorna erro
```

## ✅ **Status Final**

- **✅ Função de cálculo**: `Utils.user_size/1` implementada
- **✅ Variável de limite**: `Variables.max_size_user/0` (5GB)
- **✅ Verificação backend**: Integrada em `Context.cypher_insert/4`
- **✅ Bloqueio de upload**: Funcional no backend
- **✅ Interface frontend**: Mensagem em inglês + botões desabilitados
- **✅ Testes**: 67/67 passando com novos testes de limite
- **✅ Nomenclatura**: Seguindo padrão curto e direto

**Sistema completamente funcional e testado!** 🎉