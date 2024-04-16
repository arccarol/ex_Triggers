CREATE TABLE Times (
    CodTime INT PRIMARY KEY,
    NomeTime VARCHAR(50)
);

CREATE TABLE Jogos (
    CodTimeA INT,
    CodTimeB INT,
    SetTimeA INT,
    SetTimeB INT,
    FOREIGN KEY (CodTimeA) REFERENCES Times(CodTime),
    FOREIGN KEY (CodTimeB) REFERENCES Times(CodTime)
);


INSERT INTO Times VALUES (1, 'Time 1');
INSERT INTO Times VALUES (2, 'Time 2');
INSERT INTO Times VALUES (3, 'Time 3');
INSERT INTO Times VALUES (4, 'Time 4');


CREATE FUNCTION GetEstatisticasTimes ()
RETURNS @Estatisticas TABLE
(
    NomeTime VARCHAR(50),
    TotalPontos INT,
    TotalSetsGanhos INT,
    TotalSetsPerdidos INT,
    SetAverage INT
)
AS
BEGIN
    INSERT INTO @Estatisticas
    SELECT 
        NomeTime,
        SUM(Pontos) AS TotalPontos,
        SUM(SetsGanhos) AS TotalSetsGanhos,
        SUM(SetsPerdidos) AS TotalSetsPerdidos,
        SUM(SetsGanhos) - SUM(SetsPerdidos) AS SetAverage
    FROM (
        SELECT 
            t.NomeTime,
            CASE 
                WHEN j.SetTimeA = 3 AND j.SetTimeB < 2 THEN 3
                WHEN j.SetTimeA = 3 AND j.SetTimeB = 2 THEN 2
                ELSE 0
            END AS Pontos,
            j.SetTimeA AS SetsGanhos,
            j.SetTimeB AS SetsPerdidos
        FROM Jogos j
        JOIN Times t ON j.CodTimeA = t.CodTime
        UNION ALL
        SELECT 
            t.NomeTime,
            CASE 
                WHEN j.SetTimeB = 3 AND j.SetTimeA < 2 THEN 3
                WHEN j.SetTimeB = 3 AND j.SetTimeA = 2 THEN 2
                ELSE 0
            END AS Pontos,
            j.SetTimeB AS SetsGanhos,
            j.SetTimeA AS SetsPerdidos
        FROM Jogos j
        JOIN Times t ON j.CodTimeB = t.CodTime
    ) AS Stats
    GROUP BY NomeTime;
    
    RETURN;
END;


CREATE TRIGGER CheckJogos
ON Jogos
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT *
        FROM inserted
        WHERE (SetTimeA > 3 OR SetTimeB > 3) OR (SetTimeA + SetTimeB > 5)
    )
    BEGIN
        RAISERROR ('Erro: Inconsistência nos sets registrados.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;


INSERT INTO Jogos VALUES (1, 2, 3, 2); 

INSERT INTO Jogos VALUES (1, 2, 4, 4);

SELECT * FROM dbo.GetEstatisticasTimes();

