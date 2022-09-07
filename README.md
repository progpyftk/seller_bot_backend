# README

Onde estou trabalhando?



Trabalhando na página Contas, na qual verifica se a conta está autenticada ou não. 
- Colocar botão para excluir a conta da base de dados
- Colocar botão para autenticar e alterar o código


TAREFAS
1. Ler e refazer as próximas tarefas

2. Terminar as tarefas relacionadas aos produtos que acabaram no full

3. Planejar as próximas features do app



---------- AUTOMAÇÃO DE ANÚNCIOS QUE ACABARAM NO FULL -------
- Tabela com todos anúncios que estavam no full e não estão mais, e estão pausados por falta de estoque. Para cada um desses anúncios há um form para entrar com o valor e um botão que ao clicar adiciona o estoque nesse anúncio. FALTA: criar o axios para fazer um post na API e então aumentar o estoque.



----------------------------------------------------------------------------------
MONITAR AS VENDAS DE UM ANÚNCIOS COM GRÁFICO WWW.SELLERBOT.COM.BR/VIXLED/MLB1234567 ----
1. Criar a leitura da API de ordens e criar uma tabela com item e data da ordem
-----------------------------------------------------------------------------------------
2. Criar uma página para cada tabela de eventos
3. Planejar como será a atualização automatica dos anúncios
    3.1 a leitura da API é feita a cada 5 minutos
    3.2 os dados da página são atualizados diretamente da BD, sem chamar a API
4. Vermelho - produtos que acabaram
5. Amarelo - produtos com menos de 5 unidades
6. Verificar a questão do seller.code




Primeira Tentativa
- Code correto, tudo redondo para salvar na base de dados
response.code = 200

Segunda Tentativa
- Se rodar novamente, vamos conseguir o refresh_token
atualizou o access_tokem e code 200

Terceira Tentativa
- Fazer uma nova solicitação de CODE via link e ver o que acontece
- Notar que nesse caso o seller já tem tudo cadastrado, mas o CODE mudou
Esse fato não acarretou nenhum problema

Quarta Tentativa
- Com o code inicial errado
Atualiza o status da conta como code 400, sem conexão


# MELHORIAS FUTURAS

1. Adicionar estoque
- implementar uma atualização apenas desse anúncio. Leitura da API e atualização da base de dados e o resultado foi success.

2. Contas
- colocar botão para excluir a conta da base de dados, se uma conta estiver dando problema de autenticação, basta exclui-la e cadastrar novamente.



