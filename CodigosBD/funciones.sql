USE PicParrot;

#################
-- weekly user activity
DELIMITER $$
DROP FUNCTION IF EXISTS weekly_activity_report;
CREATE FUNCTION weekly_activity_report(id_in INT)
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE ACT INT default 0;
    IF EXISTS (SELECT id FROM users WHERE users.id = id_in) THEN
		SET ACT = (SELECT SUM(elapsed_time) FROM user_logs WHERE 
			WEEK(CURDATE()-1)=WEEK(login_at) AND id_in = user_id);
		RETURN (ACT);
	END IF;
    RETURN (ACT);
END; $$
DELIMITER ;

#################
-- return number of users between 18 and 29 who have post an storie.
DELIMITER $$
DROP FUNCTION IF EXISTS stories_age_average;
CREATE FUNCTION stories_age_average()
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE result INT;
	SET result = (SELECT COUNT(stories.user_id) FROM stories
    JOIN users
		ON stories.user_id = users.id
	WHERE users.age >= 18 and users.age <= 29);
    RETURN (result);
END; $$
DELIMITER ;
SELECT count(id) from stories;
SELECT * FROM users where id= 119;
INSERT INTO stories(storie_url, time_posted, archived, user_id, public) VALUES ('http://elijah.biz',0, 0, 119, TRUE);
INSERT INTO stories(storie_url, time_posted, archived, user_id, public) VALUES ('https://shanon.org', 0, 0, 2, FALSE);
-- number of inactive users -- with no photos or stories.
DELIMITER $$
DROP FUNCTION IF EXISTS inactive_users;
CREATE FUNCTION inactive_users()
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE result INT;
	SET result = (SELECT COUNT(users.id) #, image_url, storie_url #will show nulls
		FROM users
		LEFT JOIN photos
			ON users.id=photos.user_id 
		LEFT JOIN stories
			ON users.id=stories.user_id 
		WHERE photos.id IS NULL AND stories.id IS NULL);
    RETURN (result);
END; $$
DELIMITER ;


SELECT weekly_activity_report(6) AS activity_report;
SELECT stories_age_average() AS num_stories_18_29;
SELECT inactive_users() AS inactive_num;

