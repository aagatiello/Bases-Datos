USE PicParrot;

-- 1. Finding 5 oldest. 
SELECT *
FROM users
ORDER BY created_at
LIMIT 5;

-- 2. Most popular registration date. (We need to figure out(for example) when to schedule an ad campaign.)
SELECT DAYNAME(created_at) AS days, 
	   count(*) AS total
FROM users
GROUP BY days
ORDER BY total DESC
LIMIT 2;

-- 3. Identify inactive users(with no photos or stories),(Maybe to email them or sth).
SELECT username #, image_url, storie_url #will show nulls
FROM users
LEFT JOIN photos
	ON users.id=photos.user_id 
LEFT JOIN stories
	ON users.id=stories.user_id 
WHERE photos.id IS NULL AND stories.id IS NULL;
    
-- 4. Identify most popular photo and user who created it.
SELECT username, 
	   photos.id, 
       photos.image_url, 
       COUNT(*) AS total
FROM photos
INNER JOIN likes
	ON likes.photo_id = photos.id
INNER JOIN users
	ON photos.user_id= users.id
GROUP BY photos.id 
ORDER BY total DESC
LIMIT 1;

-- 5. Calculate avg number of photos per user
#total number of photos / total number of users
SELECT 
	(SELECT COUNT(*) FROM photos) / (SELECT COUNT(*) FROM users) AS avge;
    
-- 6. TOP 5 most popular hastags
SELECT 
	tags.tag_name, 
    COUNT(*) AS total
FROM photo_tags
JOIN tags
	ON photo_tags.tag_id = tags.id
GROUP BY photo_tags.tag_id
ORDER BY total DESC
LIMIT 5;

-- 7. Finding bots (users who have liked every single photo).
SELECT username, 
       COUNT(*) AS num_likes
FROM users 
INNER JOIN likes
	ON users.id = likes.user_id
GROUP BY likes.user_id
HAVING num_likes = (SELECT COUNT(*) FROM photos);

-- 8. ACTIVIDAD DE LOG DE LOS USUARIOS
SELECT users.username, 
	   SUM(elapsed_time) 
FROM user_logs 
JOIN users 
	ON user_logs.user_id=users.id 
WHERE WEEK(CURDATE())= WEEK(login_at) GROUP BY user_id;

-- 9. VISITAS TOTALES A LOS STORIES REALIZADAS HOY PR USUARIO
SELECT user_id, SUM(visits) 
FROM stories 
JOIN users
	ON stories.user_id=users.id
WHERE DAY(stories.created_at) = day(NOW()) GROUP BY stories.user_id;

-- 10. Todas las fotos y el username del usuario que las publico por orden alfabetico de usuario.
SELECT photos.image_url, users.username 
		FROM photos 
		JOIN users
			ON photos.user_id = users.id
				ORDER BY users.username;
                
-- 11. Todos los comentarios de todas las fotos y el username del usuario que publico el comentario por orden alfabetico de usuario.                
SELECT photos.id, photos.image_url, users.username, comments.comment_text  
		FROM comments 
		JOIN users
			ON comments.user_id = users.id
		JOIN photos
			ON  comments.photo_id = photos.id
				ORDER BY users.username;