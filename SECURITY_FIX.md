# Correção de Vulnerabilidade de Segurança - Group ID

## Problema Identificado

Foi descoberta uma vulnerabilidade crítica de segurança no sistema de gerenciamento de IDs de grupos que permitia:

1. **Acesso não autorizado**: Usuários podiam referenciar grupos de outros usuários descobrindo IDs internos
2. **Corrupção de dados**: Arquivos podiam ser movidos para grupos inexistentes ou de outros usuários
3. **Vazamento de informações**: Estrutura de pastas de outros usuários podia ser inferida

## Causa Raiz

O sistema usa dois tipos de IDs:
- **ID interno** (`id`): Auto-incremento do banco de dados
- **ID público** (`file`): Serial baseado no usuário, exposto na API

As funções `get_internal_group()` e `get_public_group()` não validavam se o grupo pertencia ao usuário que estava fazendo a operação, permitindo conversões não autorizadas entre IDs.

## Solução Implementada

### 1. Validação de Propriedade
- Criada função `validate_group_ownership(user, group_id)` que verifica se o grupo pertence ao usuário
- Todas as operações agora validam propriedade antes de converter IDs

### 2. Funções Atualizadas
**Cypher API:**
- `insert/2` - Valida group_id antes de inserir
- `update/3` - Valida group_id antes de atualizar  
- `all_group/2` - Valida group_id antes de listar

**Group API:**
- `insert/2` - Valida group_id pai antes de criar subgrupo
- `update/3` - Valida group_id antes de mover grupo
- `all_group/2` - Valida group_id antes de listar subgrupos

### 3. Constraints de Banco
Adicionada migração com constraints que garantem:
- Cyphers só podem referenciar grupos do mesmo usuário
- Grupos só podem ter pais do mesmo usuário
- IDs únicos por usuário (user_id, file)

### 4. Mensagens de Erro Melhoradas
- Erros mais descritivos: "group not found or access denied"
- Diferenciação entre "não encontrado" e "acesso negado"

## Arquivos Modificados

1. `lib/max_gallery/core/api/cypher_api.ex`
2. `lib/max_gallery/core/api/group_api.ex`
3. `priv/repo/migrations/20250127000001_add_security_constraints.exs`
4. `test/max_gallery/security_test.exs`

## Testes de Segurança

Criados testes que verificam:
- Usuários não podem inserir arquivos em grupos de outros
- Usuários não podem mover arquivos para grupos de outros
- Usuários não podem criar subgrupos em grupos de outros
- Usuários não podem listar conteúdo de grupos de outros
- Operações válidas continuam funcionando

## Impacto

- **Segurança**: Eliminada vulnerabilidade de acesso cross-user
- **Integridade**: Garantida consistência de dados
- **Compatibilidade**: Mantida API existente, apenas adicionada validação
- **Performance**: Impacto mínimo - apenas uma query adicional de validação

## Recomendações

1. **Executar migração**: `mix ecto.migrate` para aplicar constraints
2. **Executar testes**: `mix test test/max_gallery/security_test.exs`
3. **Monitorar logs**: Verificar se há tentativas de acesso não autorizado
4. **Auditoria**: Revisar dados existentes para inconsistências

## Prevenção Futura

- Sempre validar propriedade de recursos antes de operações
- Usar constraints de banco para garantir integridade
- Implementar testes de segurança para novas funcionalidades
- Revisar código regularmente para vulnerabilidades similares