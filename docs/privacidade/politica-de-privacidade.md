# Política de Privacidade — Carro na Mão

**Aplicativo:** Carro na Mão  
**Desenvolvedor:** Lucas Castro  
**Contato:** lucasengecomp@gmail.com  
**Data de vigência:** 18 de outubro de 2026  
**Versão:** 1.0

---

## Resumo

O Carro na Mão **não coleta nenhum dado pessoal** e **nenhuma informação sai do
seu dispositivo**. Tudo fica armazenado localmente, sob seu controle exclusivo.

---

## 1. Dados coletados

**Nenhum.**

O aplicativo não solicita nome, e-mail, número de telefone, localização
geográfica, identificadores de dispositivo, nem qualquer outro dado pessoal.

Informações como quilometragem, abastecimentos, manutenções e despesas que você
registra ficam **exclusivamente no banco de dados local** (SQLite) do seu
dispositivo. Esses dados nunca são enviados a nenhum servidor ou serviço externo.

---

## 2. Permissões do sistema

O aplicativo pode solicitar as seguintes permissões, descritas aqui com
transparência:

| Permissão | Por que é necessária |
|-----------|----------------------|
| **Notificações** | Para enviar lembretes de manutenção ou vencimentos que você configurou. Concedida apenas sob solicitação (opt-in). Nenhuma notificação é enviada por servidor — todas partem do próprio dispositivo via `flutter_local_notifications`. |
| **Armazenamento / compartilhamento de arquivos** | Para gerar e compartilhar arquivos CSV com os seus registros, quando você usa a função "Exportar CSV". O compartilhamento é sempre iniciado por você, nunca automático. |

Nenhuma outra permissão é utilizada.

---

## 3. Compartilhamento de dados

**Nenhum dado é compartilhado com terceiros.**

A função de exportação gera um arquivo CSV no próprio dispositivo e abre o
seletor de compartilhamento nativo do sistema operacional. A escolha do
destinatário (e-mail, nuvem pessoal etc.) é **sua e somente sua**. O aplicativo
não tem acesso ao destino escolhido.

Não há integração com redes sociais, serviços de análise (analytics),
rastreamento de anúncios ou qualquer API de terceiros.

---

## 4. Retenção e exclusão dos dados

Seus dados residem no banco de dados interno do aplicativo (SQLite) e ficam no
dispositivo enquanto o aplicativo estiver instalado.

- **Para excluir todos os dados:** basta desinstalar o aplicativo. O sistema
  operacional remove o banco de dados junto.
- Não há conta para apagar, porque não há cadastro.

---

## 5. Crianças

O aplicativo não é direcionado a crianças e não coleta intencionalmente dados de
menores de 13 anos. Por não haver coleta de qualquer dado pessoal, esta política
cumpre automaticamente as exigências aplicáveis.

---

## 6. Contato

Dúvidas ou sugestões sobre esta política:

- **E-mail:** lucasengecomp@gmail.com
- **Issues do projeto:** https://github.com/lucasengecomp/carr0-na-mao/issues

---

## 7. Alterações nesta política

Caso esta política seja atualizada, a nova versão será publicada neste mesmo
endereço com a data de vigência atualizada. Como o aplicativo não coleta dados
de contato, recomendamos consultar esta página periodicamente.

---

*Carro na Mão é um aplicativo offline-first: sem login, sem telemetria,
sem analytics. Seus dados são seus.*
