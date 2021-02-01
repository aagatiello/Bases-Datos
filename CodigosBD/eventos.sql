USE PicParrot;

DROP EVENT IF EXISTS time_controller;
CREATE EVENT time_controller ON SCHEDULE EVERY 1 second
	STARTS CURRENT_TIMESTAMP 
    ENDS CURRENT_TIMESTAMP + INTERVAL 24 hour
	DO 
		UPDATE stories
			SET time_posted = (time_posted + 1) WHERE NOT (ISNULL(id)) and archived<>1 and time_posted < 10; 


DROP EVENT IF EXISTS archived_controller;
CREATE EVENT archived_controller ON SCHEDULE EVERY 1 second
	STARTS CURRENT_TIMESTAMP 
    ENDS CURRENT_TIMESTAMP + INTERVAL 24 hour
	DO 
		UPDATE stories 
			SET archived = 1 WHERE NOT (ISNULL(id)) and archived<>1 and time_posted >= 10;
-- 		UPDATE stories
-- 			SET time_posted = (time_posted + 1) WHERE NOT (ISNULL(id)) and archived<>1 and time_posted < 24; 


INSERT INTO stories(storie_url, time_posted, archived, user_id, public) VALUES ('http://elijah.biz',0, 0, 1, TRUE);
INSERT INTO stories(storie_url, time_posted, archived, user_id, public) VALUES ('https://shanon.org', 0, 0, 2, FALSE);
SELECT * FROM stories ORDER BY id DESC;
UPDATE stories SET time_posted = time_posted + 1 WHERE ID = ANY(SELECT USERNAME FROM USERS);
SELECT time_posted FROM stories WHERE NOT (ISNULL(id)) and archived<>1;
SELECT * FROM stories;

