/*Considere um quadrangular final de times de volei com 4 times
Time 1, Time 2 Time 3 e Time 4
Todos jogarão contra todos.
Os resultados dos jogos serão armazenados em uma tabela
Tabela times
(Cod Time | Nome Time)
1 Time 1
2 Time 2
3 Time 3
4 Time 4
Jogos
(Cod Time A | Cod Time B | Set Time A | Set Time B)
*/
CREATE DATABASE campeonato
USE campeonato

CREATE TABLE times(
codigo	INT NOT NULL,
nome	VARCHAR(7),
PRIMARY KEY(codigo)
)

INSERT INTO times
VALUES(1, 'Time 1')

INSERT INTO times
VALUES(2, 'Time 2')

INSERT INTO times
VALUES(3, 'Time 3')

INSERT INTO times
VALUES(4, 'Time 4')

CREATE TABLE jogos(
codTimeA	INT		NOT NULL,
codTimeB	INT		NOT NULL,
setTimeA	INT		NOT NULL,
setTimeB	INT		NOT NULL,
FOREIGN KEY (codTimeA) REFERENCES times(codigo),
FOREIGN KEY (codTimeB) REFERENCES times(codigo),
PRIMARY KEY (codTimeA, codTimeB)
)
/*
Considera-se vencedor o time que fez 3 de 5 sets.
Se a vitória for por 3 x 2, o time vencedor ganha 2 pontos e o time perdedor ganha 1.
Se a vitória for por 3 x 0 ou 3 x 1, o vencedor ganha 3 pontos e o perdedor, 0.
Fazer uma UDF que apresente:
(Nome Time | Total Pontos | Total Sets Ganhos | Total Sets Perdidos | Set Average (Ganhos - perdidos))
Fazer uma trigger que verifique se os inserts dos sets estão corretos (Máximo 5 sets por jogo, sendo
que o vencedor tem no máximo 3 sets)*/

CREATE ALTER FUNCTION fn_resultadosJogos()
RETURNS @tabela TABLE (
	nomeTime VARCHAR(8),
	totalPontos INT,
	totalSetsGanhos INT,
	totalSetsPerdidos INT,
	setAverage INT
)
AS
BEGIN
	DECLARE @setGanho INT
	DECLARE @setPerdido INT
	DECLARE @pontos INT
	DECLARE @nome VARCHAR(8)
	DECLARE @codTime INT

	SET @codTime = 1
	WHILE ((SELECT codigo FROM times WHERE codigo = @codTime) IS NOT NULL)
	BEGIN
		SET @nome = (SELECT nome FROM times WHERE codigo = @codTime)
		INSERT INTO @tabela(nomeTime)
		VALUES (@nome)

		SET @setGanho = (SELECT ISNULL(SUM(setTimeA),0) FROM jogos WHERE codTimeA = @codTime) +
		(SELECT ISNULL(SUM(setTimeB),0) FROM jogos WHERE codTimeB = @codTime)

		SET @setPerdido = (SELECT ISNULL(SUM(setTimeB),0) FROM jogos WHERE codTimeA = @codTime) +
		(SELECT ISNULL(SUM(setTimeA),0) FROM jogos WHERE codTimeB = @codTime)

		SET @pontos = (SELECT ISNULL(COUNT(codTimeA),0) FROM jogos
		  WHERE codTimeA = @codTime AND setTimeB = 3 AND setTimeA = 2)

		SET @pontos = @pontos + ((SELECT ISNULL(COUNT(codTimeA),0) FROM jogos
		  WHERE codTimeA = @codTime AND setTimeA = 3 AND setTimeB = 2) * 2)

		SET @pontos = @pontos + ((SELECT ISNULL(COUNT(codTimeA),0) FROM jogos
		  WHERE codTimeA = @codTime AND setTimeA = 3 AND setTimeB < 2) * 3)

		SET @pontos = @pontos + (SELECT ISNULL(COUNT(codTimeB),0) FROM jogos
		  WHERE codTimeB = @codTime AND setTimeA = 3 AND setTimeB = 2)

		SET @pontos = @pontos + ((SELECT ISNULL(COUNT(codTimeA),0) FROM jogos
		  WHERE codTimeB = @codTime AND setTimeB = 3 AND setTimeA = 2) * 2)

		SET @pontos = @pontos + ((SELECT ISNULL(COUNT(codTimeA),0) FROM jogos
		  WHERE codTimeB = @codTime AND setTimeB = 3 AND setTimeA < 2) * 3)

		UPDATE @tabela
		SET totalPontos= @pontos, totalSetsGanhos = @setGanho, 
		totalSetsPerdidos = @setPerdido, setAverage = (@setGanho - @setPerdido)
		WHERE nomeTime = (SELECT nome FROM times WHERE codigo= @codTime)

		SET @codTime = @codTime + 1
	END
	RETURN
END

CREATE TRIGGER t_insSet ON jogos
AFTER INSERT
AS
BEGIN
	DECLARE @set1 INT
	DECLARE @set2 INT
	SET @set1 = (SELECT setTimeA FROM INSERTED)
	SET @set2 = (SELECT setTimeB FROM INSERTED)
	IF (@set1 + @set2 > 5)
	BEGIN
		RAISERROR('O número de sets não pode ser maior que 5', 16, 1)
		ROLLBACK TRANSACTION
	END
	IF (@set1 > 3 OR @set2 > 3)
	BEGIN
		RAISERROR('O número de sets do vencedor não pode ser maior que 3', 16, 1)
		ROLLBACK TRANSACTION
	END
END


INSERT INTO jogos
VALUES (1, 2, 3, 0)

INSERT INTO jogos
VALUES (3, 2, 2, 3)
SELECT * FROM  dbo.fn_resultadosJogos()
SELECT * FROM jogos
