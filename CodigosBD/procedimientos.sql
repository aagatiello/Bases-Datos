USE PicParrot;

-- File conteins procedures, transactions, exceptions, cursor.

##################
-- RESGISTRO
DELIMITER $$
DROP PROCEDURE IF EXISTS register;
CREATE PROCEDURE register(IN username_in VARCHAR(255), IN password_in VARCHAR(16), IN age_in INT)
BEGIN
	DECLARE EXIT HANDLER FOR 1062
		SELECT CONCAT('el username indicado ya existe') AS 'mensaje de error';
    INSERT INTO users(username, passwords, age) VALUES (username_in, password_in, age_in);
END; $$
DELIMITER ;

##################
-- SIMULAR INICIO DE SESION
DELIMITER $$
DROP PROCEDURE IF EXISTS login;
CREATE PROCEDURE login(IN username_in VARCHAR(255), IN password_in VARCHAR(16))
BEGIN
	DECLARE id_in INT;
    SET id_in = (SELECT id FROM users WHERE users.username = username_in AND users.passwords = password_in LIMIT 1);
    START TRANSACTION;
    IF EXISTS (SELECT id FROM users WHERE username = username_in AND passwords = password_in AND users.is_active = FALSE) THEN
        UPDATE users SET is_active = TRUE WHERE id = id_in;
        SELECT username, is_active FROM users WHERE id = id_in;
        SELECT 'Succesfull login' AS 'Fin de transacción'; 
        COMMIT;
	ELSE
		SELECT 'Error on login ' AS 'Fin de transacción'; 
        ROLLBACK;
    END IF;    
END; $$
DELIMITER ;

##################
-- SIMULAR FIN DE SESION
DELIMITER $$
DROP PROCEDURE IF EXISTS logout;
CREATE PROCEDURE logout(IN username_in VARCHAR(255))
BEGIN
	DECLARE id_in INT;
    SET id_in = (SELECT id FROM users WHERE users.username = username_in LIMIT 1);
    START TRANSACTION;
    IF EXISTS (SELECT id FROM users WHERE username = username_in AND users.is_active=TRUE) THEN
        UPDATE users SET is_active = FALSE WHERE id = id_in;
        SELECT username, is_active FROM users WHERE id = id_in;
        SELECT 'Succesfull logout' AS 'Fin de transacción'; 
        COMMIT;
	ELSE
		SELECT 'Error on logout ' AS 'Fin de transacción'; 
        ROLLBACK;
    END IF;    
END; $$
DELIMITER ;


#################
-- ELIMINAR LA CUENTA DE UN USUARIO
DELIMITER $$
DROP PROCEDURE IF EXISTS delete_account;
CREATE PROCEDURE delete_account(IN username_in VARCHAR(255), IN password_in VARCHAR(16))
BEGIN
	DECLARE id_in INT;
    SET id_in = (SELECT id FROM users WHERE users.username = username_in AND users.passwords = password_in LIMIT 1);
	START TRANSACTION;
	IF EXISTS (SELECT id FROM users WHERE username = username_in AND passwords = password_in) THEN
		CALL delete_relationships(id_in); 
		DELETE FROM photos WHERE photos.user_id = id_in;
		DELETE FROM users WHERE users.id=id_in;
		SELECT 'Commit' AS 'Fin de transacción'; 
		COMMIT;	
	ELSE
		SELECT 'Rollback ' AS 'Fin de transacción'; 
		ROLLBACK;
	END IF;
END; $$
DELIMITER ;

##################
-- Eliminar relacion
DELIMITER $$
DROP PROCEDURE IF EXISTS delete_relationships;
CREATE PROCEDURE delete_relationships(IN id INT)
BEGIN
	DELETE FROM relationships WHERE relationships.follower_id=id;
    DELETE FROM relationships WHERE relationships.followee_id=id;
END; $$
DELIMITER ;

##################
-- VER STORIES
DELIMITER $$
DROP PROCEDURE IF EXISTS watch_stories;
CREATE PROCEDURE watch_stories(IN id_in INT, IN me_in INT)
BEGIN
	IF EXISTS (SELECT closeuser_id FROM user_closefriends WHERE me_in=user_closefriends.user_id and id_in=user_closefriends.closeuser_id) THEN -- soy su closefriend
		SELECT users.username, users.id, stories.user_id, storie_url, public, visits FROM stories 
			JOIN users ON users.id=stories.user_id WHERE stories.user_id = id_in;
		UPDATE stories SET visits = (visits + 1) WHERE stories.user_id=id_in;
	ELSE -- solo veo publica
		SELECT users.username, users.id, stories.user_id, storie_url, public, visits FROM stories 
			JOIN users ON users.id=stories.user_id WHERE stories.user_id =id_in AND stories.public=1;
		UPDATE stories SET visits = (visits + 1) WHERE stories.user_id=id_in AND stories.public=1;
    END IF;
END; $$
DELIMITER ;

#################
-- SEND MESSAGE
DELIMITER $$
DROP PROCEDURE IF EXISTS send_message;
CREATE PROCEDURE send_message(IN me_in INT, IN message TINYTEXT, IN ind BOOLEAN, IN to_in VARCHAR(255))
BEGIN
	DECLARE id_in INT;
    START TRANSACTION;
	IF ind = TRUE THEN
		SET ID_IN = (SELECT id FROM users WHERE to_in=users.username);
		IF EXISTS (SELECT id FROM users WHERE to_in=users.username) THEN -- existe receptor
			INSERT INTO messages(transmitter_id, messages_text, individual) VALUES(me_in, message, TRUE);
            INSERT INTO message_individual(message_id, receiver_id) VALUES((SELECT id FROM messages ORDER BY id DESC LIMIT 1), id_in);
            SELECT 'MENSAJE INDIVIDUAL ENVIADO' AS 'Fin de transacción'; 
            COMMIT;
		ELSE
			SELECT 'ERROR EN EL ENVIO. No existe destinatario' AS 'Fin de transacción'; 
			ROLLBACK;
		END IF;
	ELSE
		SET ID_IN = (SELECT id FROM groups_ WHERE to_in=groups_.group_name);
		IF EXISTS (SELECT id FROM groups_ WHERE to_in=groups_.group_name) THEN -- existe el grupo
			IF EXISTS (SELECT user_id FROM user_groups WHERE group_id=id_in AND me_in=user_id) THEN -- tu perteneces al grupo
				INSERT INTO messages(transmitter_id, messages_text, individual) VALUES(me_in, message, FALSE);
				INSERT INTO group_messages(message_id, group_id) VALUES((SELECT id FROM messages ORDER BY id DESC LIMIT 1), id_in);
                SELECT 'MENSAJE ENVIADO AL GRUPO' AS 'Fin de transacción'; 
                COMMIT;
			ELSE 
				SELECT 'ERROR EN EL ENVIO. No perteneces a este grupo' AS 'Fin de transacción'; 
				ROLLBACK;
            END IF;
		ELSE 
			SELECT 'ERROR EN EL ENVIO. Este grupo no existe' AS 'Fin de transacción'; 
			ROLLBACK;
		END IF;
    END IF;
END; $$
DELIMITER ;

#################
-- SIMULAR SEGUIR A ALGUIEN
DELIMITER $$
DROP PROCEDURE IF EXISTS follow;
CREATE PROCEDURE follow(IN id_in INT, IN username_in VARCHAR(255))
BEGIN
	DECLARE id_2in INT;
    SET id_2in = (SELECT id FROM users WHERE users.username = username_in LIMIT 1);
    IF EXISTS (SELECT id FROM users WHERE username = username_in) THEN
        INSERT INTO relationships(follower_id, followee_id) VALUES (id_in, id_2in);
        SELECT follower_id, followee_id FROM relationships WHERE follower_id = id_in AND followee_id=id_2in;
    END IF;    
END; $$
DELIMITER ;

########################
-- IMPRIMIR LISTA DE FOLLOWERS
DELIMITER $$
DROP PROCEDURE IF EXISTS createFollowersList;
CREATE PROCEDURE createFollowersList (
	INOUT followersList varchar(4000), IN id_in INT
)
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE followersId INT DEFAULT 0;

	-- declare cursor for relationships id
	DEClARE curFollower 
		CURSOR FOR 
			SELECT follower_id FROM relationships WHERE followee_id = id_in;

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curFollower;

	getid: LOOP
		FETCH curFollower INTO followersId;
		IF finished = 1 THEN 
			LEAVE getid;
		END IF;
		-- build id list
		SET followersList = CONCAT(followersId,";",followersList);
	END LOOP getid;
	CLOSE curFollower;

END$$
DELIMITER ;



CALL register('Agus93', 'password', 17); -- es menor de edad!
CALL register('Agus93', 'password', 24); -- se registra correctamente
CALL register('Agus93', 'pass', 35); -- cuenta/username ya existe!

CALL delete_account('Gus93', 'pass'); -- introduce mal la contraseña
CALL delete_account('Gus93', 'password'); -- borra su cuenta correctamente


CALL login('Andre_Purdy85', 'password'); -- ID = 2. transaction 
CALL logout('Andre_Purdy85'); -- ID = 2
CALL login('Travon.Waters', 'password'); -- id = 6
CALL logout('Travon.Waters');
CALL login('Harley_Lind18', 'password'); -- id = 3
CALL logout('Harley_Lind18');
CALL login('Arely_Bogan63', 'password'); -- id = 4
CALL logout('Arely_Bogan63');
SELECT * FROM user_logs;



CALL watch_stories(2,4); --  id 2 tiene a 4 en closefriends
CALL watch_stories(2,8); --  id 2 no tiene a 8 en closefriends
CALL watch_stories(4,8);
CALL watch_stories(4,2);
CALL watch_stories(3,5);

CALL send_message(2, 'HOLA', TRUE, 'Andre_Purdy85');
SELECT * FROM messages order by id desc limit 1;
SELECT * FROM message_individual where message_id = 263;
CALL send_message(2, 'HOLA GRUPO', FALSE, 'Yo a esta gente no la conozco.');
CALL send_message(2, 'HOLA GRUPO', FALSE, 'Yo.');
SELECT * FROM messages order by id desc limit 1;
SELECT * FROM group_messages where message_id = 266;
SELECT group_name from groups_ where id= 4;


SET @followersList = ""; 
CALL createFollowersList(@followersList, 2);
SELECT @followersList;
SELECT follower_id from relationships where followee_id = 2;

CALL follow(3,'Agus123');




SELECT * FROM relationships WHERE follower_id= 2 and followee_id = 119;
SELECT * FROM users WHERE username= 'Agus123';

SELECT * FROM USERS where id=9 ORDER BY id;
SELECT * FROM PHOTOS ORDER BY user_id;
SELECT * FROM RELATIONSHIPS ORDER BY follower_id;
SELECT * FROM RELATIONSHIPS ORDER BY followee_id;
SELECT * FROM comments ORDER BY user_id;
SELECT * FROM likes ORDER BY user_id;
DELETE FROM user_logs WHERE user_id = 3 and isnull(logout_at);



