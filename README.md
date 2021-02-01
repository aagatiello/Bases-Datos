# Caso práctico de Bases de Datos

Para nuestro caso práctico hemos diseñado Picparrot, una hipotética red social centrada en compartir e intercambiar fotos, permitiendo a sus usuarios subir
imágenes en su perfil para que sean visibles a sus seguidores.

Solo se tiene que sacar una foto de la cámara o galería y compartirla con la comunidad, pudiendo elegir hacerlo temporalmente o fija en su muro. Las personas que tengan acceso a las fotos fijadas en su perfil pueden interactuar dando “me gusta” o escribiendo un comentario. Por otro lado, con imágenes temporales nos referimos a las “Historias”, que tratan de compartir fotos con un periodode tiempo de 24h antes de caducar. Éstas se han incorporado para dar la posibilidad de compartir un momento de forma más natural y rápida.

Las funcionalidades que hemos implementado para crear todo este diseño son:
- Iniciar y cerrar sesión: Con unas credenciales de nombre de usuario y contraseña.
- Eliminar cuenta: En caso de no querer seguir siendo usuario de la aplicación, se eliminarían las credenciales, las personas a las que seguías, tus fotos y comentarios.
- Subir imágenes: Te permite subir y publicar imágenes.
- Dar "me gusta”: Si te gusta una publicación puedes reaccionar a ella dando “me gusta”.
- Añadir tags, descripciones y localización: Cuando realizas una publicación, se pueden agregar dichos campos. El primero te permite conectar con otras fotos al realizar una búsqueda de esa etiqueta.
- Historias: Puedes publicar fotos que estarán disponibles sólo 24 horas. Nota: en el código haremos que esta duración sea en segundos para poder ajustarnos al tiempo de la presentación.
- Mensajería: Esta es la función para enviar mensajes privados.
- Grupos: Es posible crear un chat con varios integrantes para enviar mensajes a todos a la vez.
- Seguir y dejar de seguir: Si encuentras a una persona que te interese su contenido, como un amigo o famoso, puedes seguirlo para estar al día del contenido que sube. Si por otro lado te deja de interesar, siempre puedes dejarlo de seguir.
- Amigos cercanos: Esto solo está pensado para una finalidad, poder subir historias y limitar que solo las vean las personas que hayas metido dentro de tu lista de mejores amigos.
- Reporte de tiempo: Tiempo que un usuario haya pasado semanalmente dentro de la aplicación.

Para poder implementar estos casos, vamos a tener que usar todo tipos de consultas, incluyendo funciones, procedimientos, cursores, excepciones, triggers, eventos y transacciones:

- Media edad historias (Stories_age_average): Función. Devuelve el número de personas que han subido historias entre los 18 y 29 años.

- Reporte de tiempo (Weekly_activity_report): Función. Al pasarle un id de usuario, devuelve cuántas horas semanales ha estado ese usuario con la sesión iniciada.
 
    ↳ Capture_logs: Trigger. Guarda en la tabla “user_logs” la hora de inicio y cierre de sesión para calcular el tiempo que ha estado conectado (elapsed_time).

- Usuarios sin actividad (Inactive_users): Función. Número de usuarios que no han subido ni fotos ni historias comprobando que ambos campos son null.

- Eliminar cuenta (Delete_account): Procedimiento + transacción. Elimina un usuario si se pasa su usuario y contraseña correctamente.
 
     ↳ Eliminar relaciones (Delete_relationships): Procedimiento. Recursividad con eliminar cuenta, elimina las personas que sigues y te siguen.

- Inicio sesión (Login): Procedimiento + transacción. Comprueba que todo está bien para dejar entrar a la aplicación, sino devuelve rollback.
 
     ↳ Register_checker: Trigger + 2 excepciones (“Debe ser un adulto”, “Cuenta ya existente”).

- Cerrar sesión (Logout): Procedimiento + transacción. Entra el id del usuario, y si este había iniciado sesión previamente, la cerrará.

- Seguir usuario (Follow): Procedimiento. Pide el nombre de usuario y comprueba que a quien vayas a seguir existe.

    ↳ Prevent_selfFollow: Trigger. Evita que puedas seguirte a ti mismo.

- Dejar de seguir usuario (Unfollow): Procedimiento.

    ↳ Capture_unfollows: Trigger. Guarda en una tabla quien deja de seguir a quien.

- Mirar historias (Watch_stories): Procedimiento. Pasamos id de quién mira y del dueño de la historia para que, en caso de ser amigo cercano, pueda mirar todas las posibles historias. Además, contabiliza el número de visitas.

- Enviar mensaje (Send_message): Procedimiento + transacción. Recibe el id del usuario, el mensaje, si será individual o grupal y el destinatario.

- Registro (Registers): Procedimiento + excepción (No permite nombres de usuario repetidos).

- Lista de seguidores (createFollowersList): Cursor + excepción + procedimiento. Crea una lista de los id de personas que siguen a un usuario.

- Historias:
 
    ↳ Times_controller: Evento. Contabiliza las 24h en las que estará disponible una historia.
 
     ↳ Archived_cotroller: Evento. Al haber terminado el tiempo, se archivará y dejará de estar disponible.
