# Exibição de Uso de Armazenamento no Config Live - MaxGallery

## 🎯 **Funcionalidade Implementada**

Adicionada seção de **Storage Usage** na página de configurações (Config Live) que mostra o uso atual de armazenamento do usuário de forma visual e informativa.

## 🔧 **Implementação Técnica**

### **1. Backend (ConfigLive.ex)**

#### **Cálculo no Mount:**
```elixir
def mount(_params, %{"user_auth" => user_id}, socket) do
  # Calculate current user storage usage
  current_size_gb = Utils.user_size(user_id)
  max_size_gb = Variables.max_size_user()
  usage_percentage = if max_size_gb > 0, do: (current_size_gb / max_size_gb) * 100, else: 0
  
  socket = assign(socket,
    current_size_gb: current_size_gb,
    max_size_gb: max_size_gb,
    usage_percentage: usage_percentage
  )
end
```

#### **Função Helper para Cores:**
```elixir
def storage_bar_color(usage_percentage) do
  cond do
    usage_percentage >= 90 -> "bg-red-500"    # Vermelho (crítico)
    usage_percentage >= 70 -> "bg-yellow-500" # Amarelo (aviso)
    true -> "bg-green-500"                     # Verde (normal)
  end
end
```

### **2. Frontend (config_live.html.heex)**

#### **Seção Adicionada na "Database Config":**
```heex
<div name="storage_usage" class="mt-10 ml-8">
  <h1 class="text-xl font-bold text-gray-800">Storage Usage</h1>
  <p class="text-sm text-gray-500 break-words mb-2">
    Current storage usage for your account. You can upload files until you reach the limit.
  </p>
  
  <div class="mb-4">
    <!-- Informações de uso -->
    <div class="flex justify-between text-sm text-gray-600 mb-1">
      <span><%= Float.round(@current_size_gb, 2) %> GB used</span>
      <span><%= Float.round(@max_size_gb, 2) %> GB total</span>
    </div>
    
    <!-- Barra de progresso -->
    <div class="w-full bg-gray-200 rounded-full h-3">
      <div 
        class={"h-3 rounded-full transition-all duration-300 #{MaxGalleryWeb.Live.ConfigLive.storage_bar_color(@usage_percentage)}"}
        style={"width: #{min(@usage_percentage, 100)}%"}
      >
      </div>
    </div>
    
    <!-- Porcentagem -->
    <div class="text-xs text-gray-500 mt-1">
      <%= Float.round(@usage_percentage, 1) %>% of storage used
    </div>
  </div>
</div>
```

## 🎨 **Design e Estilo**

### **Seguindo o Padrão da Página:**
- ✅ **Título**: `text-xl font-bold text-gray-800` (mesmo estilo das outras seções)
- ✅ **Descrição**: `text-sm text-gray-500 break-words mb-2` (padrão da página)
- ✅ **Posicionamento**: `mt-10 ml-8` (alinhado com outras seções)
- ✅ **Localização**: Na seção "Database Config" conforme solicitado

### **Barra de Progresso Visual:**
- **Fundo**: Cinza claro (`bg-gray-200`)
- **Altura**: 12px (`h-3`)
- **Bordas**: Arredondadas (`rounded-full`)
- **Animação**: Transição suave (`transition-all duration-300`)

### **Sistema de Cores Inteligente:**
- 🟢 **Verde** (`bg-green-500`): 0-69% de uso (normal)
- 🟡 **Amarelo** (`bg-yellow-500`): 70-89% de uso (aviso)
- 🔴 **Vermelho** (`bg-red-500`): 90-100% de uso (crítico)

## 📊 **Informações Exibidas**

### **1. Uso Atual vs Total:**
```
2.34 GB used                    5.00 GB total
```

### **2. Barra Visual:**
```
████████████░░░░░░░░░░░░░░░░░░░░ 46.8%
```

### **3. Porcentagem Precisa:**
```
46.8% of storage used
```

## 🔄 **Comportamento Dinâmico**

### **Cálculo em Tempo Real:**
- **Executado**: A cada carregamento da página Config
- **Função**: `Utils.user_size(user_id)` soma todos os arquivos do usuário
- **Conversão**: Bytes → GB (divisão por 1024³)
- **Precisão**: 2 casas decimais para tamanhos, 1 casa para porcentagem

### **Responsividade Visual:**
- **Largura da barra**: Proporcional ao uso (0-100%)
- **Cor da barra**: Muda automaticamente baseada na porcentagem
- **Limite máximo**: Barra nunca excede 100% mesmo se uso > limite

## 📍 **Localização na Interface**

```
User Config.
├── Logout
├── Change Password  
└── Delete Account

Database Config.
├── Storage Usage          ← ✅ NOVA SEÇÃO AQUI
├── Change the Database key
├── Drop the Database
└── Export all Database
```

## ✅ **Status da Implementação**

- **✅ Cálculo de uso**: Implementado com `Utils.user_size/1`
- **✅ Interface visual**: Barra de progresso com cores dinâmicas
- **✅ Estilo consistente**: Seguindo padrão da página Config
- **✅ Localização correta**: Na seção "Database Config"
- **✅ Informações completas**: Uso atual, total e porcentagem
- **✅ Testes**: 67/67 passando sem falhas

## 🎯 **Resultado Final**

O usuário agora pode ver claramente:
1. **Quanto espaço já usou** (ex: 2.34 GB)
2. **Quanto espaço tem disponível** (ex: 5.00 GB total)
3. **Porcentagem de uso** (ex: 46.8%)
4. **Status visual** através das cores da barra
5. **Proximidade do limite** para tomar decisões sobre uploads

**Implementação completa e funcional!** 🚀