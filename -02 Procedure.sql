----------------------------------------------------------------------------------------------
/*1. Inserir novo cliente
Criando uma procedure que receba Nome e Email de um cliente inisirido na tabela Cliente.*/
-------------------------------------------------------------------------------------------------
create or alter procedure inserircliente
@nome nvarchar(100),
@email nvarchar(100)

AS
  BEGIN
        insert into Cliente(Nome,Email)
		values (@nome,@Email)
END

exec inserircliente @nome = João, @email = 'joaozinho123@gmail.com'

select * from Cliente

----------------------------------------------------------------------------------------------------
/*2. Atualizar estoque

Criando uma procedure que receba ProdutoID e Quantidade, e atualize o estoque desse produto.*/
-----------------------------------------------------------------------------------------------------

create or alter procedure atualizarEstoque
@produtoid int,
@quantidade int
AS
BEGIN
        update Produto
		set Estoque = Estoque + @quantidade
		where ProdutoID = @produtoid
END

exec atualizarEstoque @produtoid = 4, @quantidade = 3

select * from Produto

----------------------------------------------------------------------------------------------------------------------------------------
/*3. Listar pedidos de um cliente

Criando uma procedure que receba ClienteID e retorne todos os pedidos feitos por esse cliente, incluindo data do pedido e valor total.*/
------------------------------------------------------------------------------------------------------------------------------------------
create procedure PedidoCliente
@ClienteId int

as 
BEGIN
     select p.PedidoID, p.DataPedido,
           SUM(ip.Quantidade * pr.Preco) AS ValorTotal
    FROM Pedido p JOIN ItemPedido ip ON p.PedidoID = ip.PedidoID
                  JOIN Produto pr ON ip.ProdutoID = pr.ProdutoID
    WHERE p.ClienteID = @ClienteID
    GROUP BY p.PedidoID, p.DataPedido;
END;

EXEC PedidoCliente @ClienteID = 1;

-----------------------------------------------------------------------
/*4. Registrar devolução de produto

Criando uma procedure que receba PedidoID e ProdutoID e que faça:

*Remoção desse item do pedido

*Devolva a quantidade ao estoque.
*/
----------------------------------------------------------------------
create procedure RegistroDev
@pedidoId int,
@ProdutoId int
as
 BEGIN
 Declare @QNT int
        select @QNT = quantidade
		from ItemPedido
		where ProdutoID = @ProdutoId AND PedidoID = @pedidoId

		delete from ItemPedido
		where ProdutoID = @ProdutoId AND PedidoID =@pedidoId

		update Produto
		set Estoque = Estoque + @QNT
		where ProdutoID = @ProdutoId
END

-- Suponha que o cliente devolveu 1 mouse do PedidoID = 1
EXEC RegistroDev @PedidoID = 1, @ProdutoID = 2;

SELECT * FROM ItemPedido 
SELECT * FROM Produto  ProdutoID = 2;  -- Estoque atualizado

-------------------------------------------------------------------------------------------------------------------------------------------------
/*5. Relatório de vendas por categoria

Criando uma procedure que receba uma Categoria e retorne todos os produtos vendidos dessa categoria com quantidade total vendida e valor total.*/
----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE RelatórioDeVendasCate
@categoria nvarchar(50)
as
BEGIN
      select pr.Nome ,sum(it.Quantidade) as totalvendido,
	         sum(it.quantidade * preço) as valortotal
	  from ItemPedido it join Produto pr on it.ProdutoID = pr.ProdutoID 
	  where pr.Categoria = @categoria
	  group by pr.Nome
END

EXEC RelatórioDeVendasCate @Categoria = 'Informática';

---------------------------------------------------------------------------------------------------------------------------------
/*6. Clientes com gastos acima de um valor

Criando uma procedure que receba um parâmetro @ValorMinimo e que liste os clientes cujo total gasto seja maior que esse valor.*/
-----------------------------------------------------------------------------------------------------------------------------------
create or alter procedure ClienteAltoValor

@ValorMinimo decimal (10,2)
as
BEGIN 
     SELECT c.Nome,
           SUM(ip.Quantidade * pr.Preco) AS TotalGasto
    FROM Cliente c
    JOIN Pedido p ON c.ClienteID = p.ClienteID
    JOIN ItemPedido ip ON p.PedidoID = ip.PedidoID
    JOIN Produto pr ON ip.ProdutoID = pr.ProdutoID
    GROUP BY c.Nome
	Having sum(ip.Quantidade * pr.Preco) > @ValorMinimo
END

EXEC ClienteAltoValor @ValorMinimo = 530;

--------------------------------------------------------------------------------------------------------------------
/*7. Ranking de produtos mais vendidos

Criando uma procedure que receba @TopN e retorne os N produtos mais vendidos, em ordem decrescente de quantidade.*/
---------------------------------------------------------------------------------------------------------------------
create or alter procedure RankProduto
@topn int

as 
BEGIN  
       select top (@topn) pr.nome ,sum(quantidade) as 'TotalVendido',
	   rank() over(order by sum(quantidade) desc) as Ranking
	   from ItemPedido it join Produto pr on it.ProdutoID = pr.ProdutoID	    
	   group by pr.Nome

END
execute  RankProduto @topn = 3


CREATE OR ALTER PROCEDURE sp_TopProdutos
    @TopN INT
AS
BEGIN
    SELECT TOP (@TopN) pr.Nome,
           SUM(ip.Quantidade) AS TotalVendido
    FROM Produto pr
    JOIN ItemPedido ip ON pr.ProdutoID = ip.ProdutoID
    GROUP BY pr.Nome
    ORDER BY TotalVendido DESC;
END;

EXEC sp_TopProdutos @TopN = 3;
------------------------------------------------------------------------------
/*8. Registrar pedido 

Criando uma procedure que receba ClienteID, ProdutoID e Quantidade, e:

Insira o pedido.

Insira o item no pedido.

Atualize o estoque do produto. */
-----------------------------------------------------------------------------

create or alter procedure RegistrarPedido
@ClienteID int,
@ProdutoId int,
@Quantidade int

as
BEGIN
    Declare @pedidoid int

	insert into Pedido (ClienteID) 
	values (@ClienteId)
	set @pedidoid = SCOPE_IDENTITY()

	insert into ItemPedido(ProdutoID,Quantidade,PedidoID)
	values (@ProdutoId,@Quantidade,@pedidoid)

	update Produto
	set Estoque = Estoque - @Quantidade
	where produtoid = @produtoid
END

EXEC RegistrarPedido @ClienteID = 2, @ProdutoID = 3, @Quantidade = 1;

SELECT * FROM Pedido WHERE ClienteID = 2;

SELECT * FROM ItemPedido;

SELECT * FROM Produto WHERE ProdutoID = 3;

----------------------------------------------------------
/*9. Histórico de um cliente

Criando uma procedure que receba ClienteID e retorne:

Nome do cliente

Lista de pedidos com valores totais

Total gasto por ele */
------------------------------------------------------------
create procedure HistóricoCliente
@ClienteId int

as
BEGIN  
      SELECT c.Nome,
           p.PedidoID,
           p.DataPedido,
           SUM(ip.Quantidade * pr.Preco) AS ValorPedido
    FROM Cliente c
    JOIN Pedido p ON c.ClienteID = p.ClienteID
    JOIN ItemPedido ip ON p.PedidoID = ip.PedidoID
    JOIN Produto pr ON ip.ProdutoID = pr.ProdutoID
    WHERE c.ClienteID = @ClienteID
    GROUP BY c.Nome, p.PedidoID, p.DataPedido;

    -- Total geral
    SELECT c.Nome,
           SUM(ip.Quantidade * pr.Preco) AS TotalGasto
    FROM Cliente c
    JOIN Pedido p ON c.ClienteID = p.ClienteID
    JOIN ItemPedido ip ON p.PedidoID = ip.PedidoID
    JOIN Produto pr ON ip.ProdutoID = pr.ProdutoID
    WHERE c.ClienteID = @ClienteID
    GROUP BY c.Nome;
END;

EXEC HistóricoCliente @ClienteID = 2;
-------------------------------------------------------------------------------------------------------------------------------------------
/*10. Relatório mensal de vendas

Criando uma procedure que receba @Ano e @Mes, e mostre o total de vendas (em dinheiro) e a quantidade de pedidos feitos nesse período. */
-------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_VendasMensais
    @Ano INT,
    @Mes INT
AS
BEGIN
    SELECT COUNT(DISTINCT p.PedidoID) AS TotalPedidos,
           SUM(ip.Quantidade * pr.Preco) AS ValorTotal
    FROM Pedido p
    JOIN ItemPedido ip ON p.PedidoID = ip.PedidoID
    JOIN Produto pr ON ip.ProdutoID = pr.ProdutoID
    WHERE YEAR(p.DataPedido) = @Ano
      AND MONTH(p.DataPedido) = @Mes;
END;
