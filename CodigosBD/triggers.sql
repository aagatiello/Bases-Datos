USE PicParrot;

#################
-- prevent UNDER AGE users.
DELIMITER $$
DROP TRIGGER IF EXISTS register_checker;
CREATE TRIGGER register_checker
	BEFORE INSERT ON users FOR EACH ROW
    BEGIN
		IF new.age < 18 THEN 
			SIGNAL SQLSTATE '45000'
				SET message_text = 'MUST BE AN ADULT.';
		ELSE 
			IF EXISTS (SELECT id FROM users WHERE username = new.username) THEN
				SIGNAL SQLSTATE '45000'
					SET  message_text = 'ACCOUNT ALREADY EXISTS';
            END IF;
		END IF;
	END;$$
DELIMITER ;

#################
-- prevent user for following themselfs
DELIMITER $$
DROP TRIGGER IF EXISTS prevent_self_follows;
CREATE TRIGGER prevent_self_follows
	BEFORE INSERT ON relationships FOR EACH ROW
    BEGIN
		IF new.follower_id = new.followee_id
		THEN
			SIGNAL SQLSTATE '45000' #generic state representing unhandled user-define exception
				SET message_text = 'YOU CANNOT FOLLOW YOURSELF';
        END IF;
	END;$$
DELIMITER ;


#################
-- manage unfollows
DELIMITER $$
DROP TRIGGER IF EXISTS capture_unfollow;
CREATE TRIGGER capture_unfollow
	AFTER DELETE ON relationships FOR EACH ROW
    BEGIN
		INSERT INTO unfollows
			SET follower_id = old.follower_id,
				followee_id = old.followee_id;
	END$$
DELIMITER ;
DESCRIBE unfollows;
#################
-- DROP TRIGGER IF EXISTS capture_logs;
-- manage user activity
DELIMITER $$
DROP TRIGGER IF EXISTS capture_logs;
CREATE TRIGGER capture_logs
	AFTER UPDATE ON users FOR EACH ROW
    BEGIN
		IF(new.is_active = TRUE) THEN
			INSERT INTO user_logs
				SET user_id = old.id,
					login_at = NOW();
		ELSEIF(new.is_active = FALSE) THEN
			UPDATE user_logs 
				SET logout_at = NOW(),
					elapsed_time = (SELECT TIMESTAMPDIFF( MINUTE, login_at, logout_at)) WHERE user_id=new.id ORDER BY login_at DESC LIMIT 1;
		END IF;
	END;$$
DELIMITER ;



DELETE FROM relationships WHERE follower_id=2 AND followee_id = 1;
SELECT * FROM unfollows;
DELETE FROM relationships WHERE follower_id=3;
SELECT * FROM unfollows;
SELECT * FROM user_logs; -- WHERE user_id=2 ORDER BY login_at DESC LIMIT 1;

