CREATE OR REPLACE FUNCTION
disqualifyHorseInRaceFunction (theHorseID INTEGER, theRacetrackID INTEGER, theRaceDate DATE, theRaceNum INTEGER)
RETURNS INTEGER AS $$
    DECLARE countUpdates INTEGER;
    DECLARE testExisting INTEGER;
    DECLARE testNull INTEGER;
    DECLARE i INTEGER; 

    DECLARE disqualifyPosition INTEGER;

    DECLARE FindFinishPosition CURSOR FOR
        SELECT hrr.finishPosition
        FROM HorseRaceResults hrr
        WHERE hrr.horseID = theHorseID
        AND hrr.raceDate = theRaceDate
        AND hrr.raceNum = theRaceNum
        AND hrr.racetrackID = theRacetrackID;

    DECLARE checkRowCount CURSOR FOR
        SELECT COUNT(*)
        FROM HorseRaceResults hrr
        WHERE hrr.horseID = theHorseID
        AND hrr.raceDate = theRaceDate
        AND hrr.raceNum = theRaceNum
        AND hrr.racetrackID = theRacetrackID;

    DECLARE checkNull CURSOR FOR
        SELECT COUNT(*)
        FROM HorseRaceResults hrr
        WHERE hrr.horseID = theHorseID
        AND hrr.raceDate = theRaceDate
        AND hrr.raceNum = theRaceNum
        AND hrr.racetrackID = theRacetrackID
        AND hrr.finishPosition IS NULL;
    
    BEGIN
    OPEN FindFinishPosition;
    OPEN checkRowCount;
    OPEN checkNull;
    FETCH checkRowCount INTO testExisting;
    FETCH checkNull INTO testNull;
    FETCH FindFinishPosition INTO disqualifyPosition;

    IF testExisting = 0 THEN
        RETURN -1;

    ELSIF testNull > 0 THEN
        RETURN -2;
    
    ELSE
        UPDATE HorseRaceResults
        SET  finishPosition = NULL
        WHERE horseID = theHorseID
        AND raceDate = theRaceDate
        AND raceNum = theRaceNum
        AND racetrackID = theRacetrackID; 
        
        countUpdates := 0;
        disqualifyPosition := disqualifyPosition + 1;
        LOOP
            EXIT WHEN (SELECT MAX(hrr.finishPosition)
                        FROM HorseRaceResults hrr
                        WHERE hrr.raceDate = theRaceDate
                        AND hrr.raceNum = theRaceNum
                        AND hrr.racetrackID = theRacetrackID) < disqualifyPosition;

            UPDATE HorseRaceResults
            SET finishPosition = disqualifyPosition - 1
            WHERE finishPosition = disqualifyPosition
            AND raceDate = theRaceDate
            AND raceNum = theRaceNum
            AND racetrackID = theRacetrackID;

            GET DIAGNOSTICS i = ROW_COUNT;
            countUpdates := countUpdates + i;
            disqualifyPosition := disqualifyPosition + 1;

        END LOOP;
            
        RETURN countUpdates;
        END IF;

    CLOSE checkRowCount;
    CLOSE checkNull; 

    END

$$ LANGUAGE plpgsql;