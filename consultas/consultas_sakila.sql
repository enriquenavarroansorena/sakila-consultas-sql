/* ============================================================================
   DataProject: Lógica — Consultas de SQL
   Base de datos : Sakila (tienda de alquiler de películas) · PostgreSQL 18
   Herramienta   : DBeaver
   Autor         : Enrique Navarro
   ----------------------------------------------------------------------------
   Convenciones seguidas:
     - Palabras clave en MAYÚSCULAS, identificadores en minúscula.
     - Un alias corto y con sentido por tabla (f = film, a = actor, ...).
     - JOIN ... ON explícito; nunca joins implícitos con comas.
     - Una cláusula por línea y sangría consistente.
     - Cada consulta va precedida de su número y su enunciado literal.
   ========================================================================== */


-- ---------------------------------------------------------------------------
-- 1. Crea el esquema de la BBDD.
-- ---------------------------------------------------------------------------
-- La BBDD se ha creado ejecutando el script bbdd/BBDD_Proyecto_shakila_sinuser.sql sobre una
-- base de datos vacía llamada "sakila" (el dump no incluye CREATE DATABASE).
-- El diagrama entidad-relación está en images/esquema_bbdd.png.
-- Consulta de apoyo para listar las tablas creadas:
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ---------------------------------------------------------------------------
-- 2. Muestra los nombres de todas las películas con una clasificación por edades de 'R'.
-- ---------------------------------------------------------------------------
SELECT title
FROM film
WHERE rating = 'R'
ORDER BY title;

-- ---------------------------------------------------------------------------
-- 3. Encuentra los nombres de los actores que tengan un "actor_id" entre 30 y 40.
-- ---------------------------------------------------------------------------
SELECT actor_id, first_name, last_name
FROM actor
WHERE actor_id BETWEEN 30 AND 40   -- BETWEEN incluye ambos extremos
ORDER BY actor_id;

-- ---------------------------------------------------------------------------
-- 4. Obtén las películas cuyo idioma coincide con el idioma original.
-- ---------------------------------------------------------------------------
SELECT f.title, l.name AS idioma
FROM film AS f
JOIN language AS l ON l.language_id = f.language_id
WHERE f.language_id = f.original_language_id;
-- Devuelve 0 filas. No es un error de la consulta: en esta BBDD la columna
-- original_language_id es NULL en las 1.000 películas, y en SQL NULL no es igual
-- a ningún valor, ni siquiera a sí mismo. Comprobación:
--   SELECT COUNT(*) FROM film WHERE original_language_id IS NOT NULL;  -- 0
-- Conclusión: el dato de idioma original no se ha registrado nunca, así que la
-- pregunta no puede responderse con la información disponible.

-- ---------------------------------------------------------------------------
-- 5. Ordena las películas por duración de forma ascendente.
-- ---------------------------------------------------------------------------
SELECT title, length AS duracion_min
FROM film
ORDER BY length ASC;


-- ---------------------------------------------------------------------------
-- 6. Encuentra el nombre y apellido de los actores que tengan 'Allen' en su apellido.
-- ---------------------------------------------------------------------------
SELECT first_name, last_name
FROM actor
WHERE last_name ILIKE '%allen%'   -- ILIKE: los datos están en mayúsculas (ALLEN)
ORDER BY first_name;


-- ---------------------------------------------------------------------------
-- 7. Encuentra la cantidad total de películas en cada clasificación de la tabla "film" y muestra la clasificación junto con el recuento.
-- ---------------------------------------------------------------------------
SELECT rating AS clasificacion,
       COUNT(*) AS num_peliculas
FROM film
GROUP BY rating
ORDER BY num_peliculas DESC;

-- ---------------------------------------------------------------------------
-- 8. Encuentra el título de todas las películas que son 'PG-13' o tienen una duración mayor a 3 horas en la tabla film.
-- ---------------------------------------------------------------------------
SELECT title, rating, length AS duracion_min
FROM film
WHERE rating = 'PG-13'
   OR length > 180   -- 3 horas = 180 minutos; length está expresado en minutos
ORDER BY title;

-- ---------------------------------------------------------------------------
-- 9. Encuentra la variabilidad de lo que costaría reemplazar las películas.
-- ---------------------------------------------------------------------------
SELECT ROUND(AVG(replacement_cost), 2)      AS coste_medio,
       ROUND(VAR_SAMP(replacement_cost), 2) AS varianza,
       ROUND(STDDEV_SAMP(replacement_cost), 2) AS desviacion_tipica,
       MIN(replacement_cost)                AS coste_minimo,
       MAX(replacement_cost)                AS coste_maximo
FROM film;
-- La varianza está en "dólares al cuadrado" y no es interpretable directamente;
-- la desviación típica sí, porque vuelve a las unidades originales.

-- ---------------------------------------------------------------------------
-- 10. Encuentra la mayor y menor duración de una película de nuestra BBDD.
-- ---------------------------------------------------------------------------
SELECT MIN(length) AS duracion_minima,
       MAX(length) AS duracion_maxima
FROM film;

-- ---------------------------------------------------------------------------
-- 11. Encuentra lo que costó el antepenúltimo alquiler ordenado por día.
-- ---------------------------------------------------------------------------
SELECT r.rental_id,
       r.rental_date,
       p.amount AS importe
FROM rental AS r
LEFT JOIN payment AS p ON p.rental_id = r.rental_id   -- LEFT: hay alquileres sin pago registrado
ORDER BY r.rental_date DESC, r.rental_id DESC          -- desempate por id: ver nota
OFFSET 2 LIMIT 1;                                      -- saltamos 2 → el 3º por la cola
-- Nota: "ordenado por día" tiene una ambigüedad importante en esta BBDD. Los 182 últimos
-- alquileres comparten exactamente la misma fecha y hora (2006-02-14 15:16:03), así que
-- "el antepenúltimo" no está definido solo con la fecha: hace falta un criterio de desempate,
-- aquí rental_id. Sin el ORDER BY secundario, el resultado podría cambiar entre ejecuciones.


-- ---------------------------------------------------------------------------
-- 12. Encuentra el título de las películas en la tabla "film" que no sean ni 'NC-17' ni 'G' en cuanto a su clasificación.
-- ---------------------------------------------------------------------------
SELECT title, rating
FROM film
WHERE rating NOT IN ('NC-17', 'G')
ORDER BY title;
-- Cuidado: si rating pudiera ser NULL, NOT IN excluiría también esas filas (NULL no es
-- comparable). Aquí no ocurre, pero es un fallo clásico.

-- ---------------------------------------------------------------------------
-- 13. Encuentra el promedio de duración de las películas para cada clasificación de la tabla film y muestra la clasificación junto con el promedio de duración.
-- ---------------------------------------------------------------------------
SELECT rating AS clasificacion,
       COUNT(*) AS num_peliculas,
       ROUND(AVG(length), 2) AS duracion_media_min
FROM film
GROUP BY rating
ORDER BY duracion_media_min DESC;

-- ---------------------------------------------------------------------------
-- 14. Encuentra el título de todas las películas que tengan una duración mayor a 180 minutos.
-- ---------------------------------------------------------------------------
SELECT title, length AS duracion_min
FROM film
WHERE length > 180
ORDER BY length DESC, title;


-- ---------------------------------------------------------------------------
-- 15. ¿Cuánto dinero ha generado en total la empresa?
-- ---------------------------------------------------------------------------
SELECT SUM(amount) AS ingresos_totales,
       COUNT(*)    AS num_pagos,
       ROUND(AVG(amount), 2) AS ticket_medio
FROM payment;
-- Los ingresos se miden sobre payment, no sobre rental: un alquiler registrado sin pago
-- no genera ingreso.

-- ---------------------------------------------------------------------------
-- 16. Muestra los 10 clientes con mayor valor de id.
-- ---------------------------------------------------------------------------
SELECT customer_id, first_name, last_name, email
FROM customer
ORDER BY customer_id DESC
LIMIT 10;

-- ---------------------------------------------------------------------------
-- 17. Encuentra el nombre y apellido de los actores que aparecen en la película con título 'Egg Igby'.
-- ---------------------------------------------------------------------------
SELECT a.first_name, a.last_name
FROM actor AS a
JOIN film_actor AS fa ON fa.actor_id = a.actor_id
JOIN film       AS f  ON f.film_id   = fa.film_id
WHERE f.title ILIKE 'Egg Igby'   -- los títulos están en mayúsculas: EGG IGBY
ORDER BY a.last_name;


-- ---------------------------------------------------------------------------
-- 18. Selecciona todos los nombres de las películas únicos.
-- ---------------------------------------------------------------------------
SELECT DISTINCT title
FROM film
ORDER BY title;
-- Devuelve 1.000 filas, las mismas que sin DISTINCT: no hay títulos repetidos en la BBDD.
-- El DISTINCT es por tanto redundante aquí, aunque el enunciado lo pida explícitamente.

-- ---------------------------------------------------------------------------
-- 19. Encuentra el título de las películas que son comedias y tienen una duración mayor a 180 minutos en la tabla "film".
-- ---------------------------------------------------------------------------
SELECT f.title,
       f.length AS duracion_min
FROM film AS f
JOIN film_category AS fc ON fc.film_id     = f.film_id
JOIN category      AS c  ON c.category_id  = fc.category_id
WHERE c.name = 'Comedy'
  AND f.length > 180
ORDER BY f.length DESC;
-- 'Comedy' sí va con mayúscula inicial: los nombres de categoría no están en mayúsculas
-- completas, a diferencia de títulos y actores.


-- ---------------------------------------------------------------------------
-- 20. Encuentra las categorías de películas que tienen un promedio de duración superior a 110 minutos y muestra el nombre de la categoría junto con el promedio de duración.
-- ---------------------------------------------------------------------------
SELECT c.name AS categoria,
       COUNT(*) AS num_peliculas,
       ROUND(AVG(f.length), 2) AS duracion_media_min
FROM category AS c
JOIN film_category AS fc ON fc.category_id = c.category_id
JOIN film          AS f  ON f.film_id      = fc.film_id
GROUP BY c.name
HAVING AVG(f.length) > 110      -- HAVING filtra sobre el agregado; WHERE no podría hacerlo
ORDER BY duracion_media_min DESC;

-- ---------------------------------------------------------------------------
-- 21. ¿Cuál es la media de duración del alquiler de las películas?
-- ---------------------------------------------------------------------------
-- El enunciado admite dos lecturas y conviene responder a las dos:
-- a) Los días de alquiler contratados según el catálogo (film.rental_duration):
SELECT ROUND(AVG(rental_duration), 2) AS dias_alquiler_contratados
FROM film;

-- b) Los días reales que los clientes tardan en devolver (rental):
SELECT ROUND(AVG(EXTRACT(EPOCH FROM (return_date - rental_date)) / 86400)::numeric, 2)
       AS dias_alquiler_reales
FROM rental
WHERE return_date IS NOT NULL;   -- excluimos los alquileres aún no devueltos


-- ---------------------------------------------------------------------------
-- 22. Crea una columna con el nombre y apellidos de todos los actores y actrices.
-- ---------------------------------------------------------------------------
SELECT actor_id,
       first_name || ' ' || last_name AS nombre_completo
FROM actor
ORDER BY nombre_completo;
-- El operador || es el estándar SQL de concatenación. Ojo: si algún campo fuese NULL,
-- el resultado completo sería NULL; CONCAT() trataría el NULL como cadena vacía.


-- ---------------------------------------------------------------------------
-- 23. Números de alquiler por día, ordenados por cantidad de alquiler de forma descendente.
-- ---------------------------------------------------------------------------
SELECT rental_date::date AS dia,
       COUNT(*) AS num_alquileres
FROM rental
GROUP BY dia
ORDER BY num_alquileres DESC;
-- rental_date::date corta la hora y deja solo la fecha, que es lo que permite agrupar por día.


-- ---------------------------------------------------------------------------
-- 24. Encuentra las películas con una duración superior al promedio.
-- ---------------------------------------------------------------------------
SELECT title, length AS duracion_min
FROM film
WHERE length > (SELECT AVG(length) FROM film)   -- subconsulta escalar: devuelve un único valor
ORDER BY length DESC;


-- ---------------------------------------------------------------------------
-- 25. Averigua el número de alquileres registrados por mes.
-- ---------------------------------------------------------------------------
SELECT DATE_TRUNC('month', rental_date)::date AS mes,
       COUNT(*) AS num_alquileres
FROM rental
GROUP BY mes
ORDER BY mes;
-- DATE_TRUNC('month', ...) lleva cada fecha al día 1 de su mes, agrupando por mes real
-- (año + mes). Usar solo EXTRACT(MONTH...) mezclaría meses de años distintos.


-- ---------------------------------------------------------------------------
-- 26. Encuentra el promedio, la desviación estándar y varianza del total pagado.
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS num_pagos,
       ROUND(AVG(amount), 4)        AS media,
       ROUND(STDDEV_SAMP(amount), 4) AS desviacion_tipica,
       ROUND(VAR_SAMP(amount), 4)    AS varianza
FROM payment;


-- ---------------------------------------------------------------------------
-- 27. ¿Qué películas se alquilan por encima del precio medio?
-- ---------------------------------------------------------------------------
SELECT title, rental_rate AS precio_alquiler
FROM film
WHERE rental_rate > (SELECT AVG(rental_rate) FROM film)
ORDER BY rental_rate DESC, title;

-- ---------------------------------------------------------------------------
-- 28. Muestra el id de los actores que hayan participado en más de 40 películas.
-- ---------------------------------------------------------------------------
SELECT fa.actor_id,
       a.first_name || ' ' || a.last_name AS actor,
       COUNT(*) AS num_peliculas
FROM film_actor AS fa
JOIN actor AS a ON a.actor_id = fa.actor_id
GROUP BY fa.actor_id, a.first_name, a.last_name
HAVING COUNT(*) > 40
ORDER BY num_peliculas DESC;

-- ---------------------------------------------------------------------------
-- 29. Obtener todas las películas y, si están disponibles en el inventario, mostrar la cantidad disponible.
-- ---------------------------------------------------------------------------
SELECT f.film_id,
       f.title,
       COUNT(i.inventory_id) AS copias_en_inventario
FROM film AS f
LEFT JOIN inventory AS i ON i.film_id = f.film_id   -- LEFT: queremos TODAS las películas
GROUP BY f.film_id, f.title
ORDER BY copias_en_inventario, f.title;
-- COUNT(i.inventory_id) y no COUNT(*): con LEFT JOIN, COUNT(*) contaría 1 para las películas
-- sin copias (la fila con NULLs), mientras que COUNT de una columna ignora los NULL y da 0.

-- ---------------------------------------------------------------------------
-- 30. Obtener los actores y el número de películas en las que ha actuado.
-- ---------------------------------------------------------------------------
SELECT a.actor_id,
       a.first_name || ' ' || a.last_name AS actor,
       COUNT(fa.film_id) AS num_peliculas
FROM actor AS a
LEFT JOIN film_actor AS fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY num_peliculas DESC;

-- ---------------------------------------------------------------------------
-- 31. Obtener todas las películas y mostrar los actores que han actuado en ellas, incluso si algunas películas no tienen actores asociados.
-- ---------------------------------------------------------------------------
SELECT f.film_id,
       f.title,
       a.first_name || ' ' || a.last_name AS actor
FROM film AS f
LEFT JOIN film_actor AS fa ON fa.film_id  = f.film_id
LEFT JOIN actor      AS a  ON a.actor_id  = fa.actor_id
ORDER BY f.title, actor;
-- Dos LEFT JOIN encadenados: si el segundo fuese INNER, las películas sin actor
-- desaparecerían igualmente. En esta BBDD hay 3 películas sin actores asociados,
-- que aparecen con actor = NULL. Para verlas:
--   ... WHERE fa.actor_id IS NULL


-- ---------------------------------------------------------------------------
-- 32. Obtener todos los actores y mostrar las películas en las que han actuado, incluso si algunos actores no han actuado en ninguna película.
-- ---------------------------------------------------------------------------
SELECT a.actor_id,
       a.first_name || ' ' || a.last_name AS actor,
       f.title
FROM actor AS a
LEFT JOIN film_actor AS fa ON fa.actor_id = a.actor_id
LEFT JOIN film       AS f  ON f.film_id   = fa.film_id
ORDER BY actor, f.title;
-- Es la imagen especular de la 31: ahora la tabla "protegida" es actor.
-- Aquí el LEFT no cambia el resultado (los 200 actores tienen películas), pero
-- escribirlo así es lo que responde literalmente a lo que pide el enunciado.


-- ---------------------------------------------------------------------------
-- 33. Obtener todas las películas que tenemos y todos los registros de alquiler.
-- ---------------------------------------------------------------------------
SELECT f.film_id,
       f.title,
       r.rental_id,
       r.rental_date
FROM film AS f
FULL OUTER JOIN inventory AS i ON i.film_id      = f.film_id
FULL OUTER JOIN rental    AS r ON r.inventory_id = i.inventory_id
ORDER BY f.title NULLS LAST, r.rental_date;
-- FULL OUTER JOIN: conserva las dos partes. Aparecen las 42 películas sin copias
-- en inventario (rental_id NULL) y la copia que nunca se ha alquilado.
-- Hay que pasar por inventory porque film y rental no se relacionan directamente:
-- lo que se alquila es una copia física, no el título.

-- ---------------------------------------------------------------------------
-- 34. Encuentra los 5 clientes que más dinero se hayan gastado con nosotros.
-- ---------------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS cliente,
       SUM(p.amount) AS total_gastado,
       COUNT(*)      AS num_pagos
FROM customer AS c
JOIN payment  AS p ON p.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_gastado DESC
LIMIT 5;
-- Ojo: los puestos 4º y 5º empatan a 194,61 €, así que el LIMIT 5 deja fuera a un
-- cliente con el mismo gasto que el quinto. Si se quisiera incluir a los empatados,
-- habría que usar RANK() en lugar de LIMIT.

-- ---------------------------------------------------------------------------
-- 35. Selecciona todos los actores cuyo primer nombre es 'Johnny'.
-- ---------------------------------------------------------------------------
SELECT actor_id, first_name, last_name
FROM actor
WHERE first_name ILIKE 'Johnny'   -- datos en mayúsculas: JOHNNY
ORDER BY last_name;

-- ---------------------------------------------------------------------------
-- 36. Renombra la columna "first_name" como Nombre y "last_name" como Apellido.
-- ---------------------------------------------------------------------------
SELECT first_name AS "Nombre",
       last_name  AS "Apellido"
FROM actor
ORDER BY "Apellido", "Nombre";
-- Las comillas dobles conservan las mayúsculas del alias. Sin ellas, PostgreSQL
-- pasaría los identificadores a minúscula y las columnas saldrían como nombre/apellido.

-- ---------------------------------------------------------------------------
-- 37. Encuentra el ID del actor más bajo y más alto en la tabla actor.
-- ---------------------------------------------------------------------------
SELECT MIN(actor_id) AS id_minimo,
       MAX(actor_id) AS id_maximo
FROM actor;


-- ---------------------------------------------------------------------------
-- 38. Cuenta cuántos actores hay en la tabla "actor".
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS num_actores
FROM actor;

-- ---------------------------------------------------------------------------
-- 39. Selecciona todos los actores y ordénalos por apellido en orden ascendente.
-- ---------------------------------------------------------------------------
SELECT actor_id, first_name, last_name
FROM actor
ORDER BY last_name ASC, first_name ASC;   -- 2º criterio para que el orden sea estable


-- ---------------------------------------------------------------------------
-- 40. Selecciona las primeras 5 películas de la tabla "film".
-- ---------------------------------------------------------------------------
SELECT film_id, title, length, rating
FROM film
ORDER BY film_id
LIMIT 5;
-- "Las primeras" exige un ORDER BY explícito: sin él, SQL no garantiza ningún orden
-- y el resultado podría variar entre ejecuciones. Aquí usamos film_id.

-- ---------------------------------------------------------------------------
-- 41. Agrupa los actores por su nombre y cuenta cuántos actores tienen el mismo nombre. ¿Cuál es el nombre más repetido?
-- ---------------------------------------------------------------------------
SELECT first_name AS nombre,
       COUNT(*) AS num_actores
FROM actor
GROUP BY first_name
ORDER BY num_actores DESC, nombre;
-- Respuesta: no hay un único nombre más repetido. Tres nombres empatan con 4 actores
-- cada uno: KENNETH, PENELOPE y JULIA. Hay 128 nombres distintos para 200 actores.
-- Por eso la consulta lleva 'nombre' como segundo criterio de ordenación: para que el
-- empate se muestre siempre en el mismo orden.


-- ---------------------------------------------------------------------------
-- 42. Encuentra todos los alquileres y los nombres de los clientes que los realizaron.
-- ---------------------------------------------------------------------------
SELECT r.rental_id,
       r.rental_date,
       c.customer_id,
       c.first_name || ' ' || c.last_name AS cliente
FROM rental   AS r
JOIN customer AS c ON c.customer_id = r.customer_id   -- INNER: todo alquiler tiene cliente
ORDER BY r.rental_date;

-- ---------------------------------------------------------------------------
-- 43. Muestra todos los clientes y sus alquileres si existen, incluyendo aquellos que no tienen alquileres.
-- ---------------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS cliente,
       r.rental_id,
       r.rental_date
FROM customer AS c
LEFT JOIN rental AS r ON r.customer_id = c.customer_id
ORDER BY c.customer_id, r.rental_date;

-- El LEFT JOIN es lo que pide el enunciado, aunque en esta BBDD no cambie el resultado:
-- los 599 clientes tienen alquileres (entre 12 y 46 cada uno, media de 26,8).
-- Para comprobarlo: ... WHERE r.rental_id IS NULL  → 0 filas.

-- ---------------------------------------------------------------------------
-- 44. Realiza un CROSS JOIN entre las tablas film y category. ¿Aporta valor esta consulta? ¿Por qué? Deja después de la consulta la contestación.
-- ---------------------------------------------------------------------------
SELECT f.film_id,
       f.title,
       c.category_id,
       c.name AS categoria
FROM film AS f
CROSS JOIN category AS c
ORDER BY f.title, c.name;
-- RESPUESTA: no, esta consulta no aporta valor.
-- Un CROSS JOIN devuelve el producto cartesiano: cada película emparejada con TODAS las
-- categorías, 1.000 x 16 = 16.000 filas. El resultado afirma cosas falsas, como que
-- ACADEMY DINOSAUR pertenece a la vez a Action, Horror y Music.
-- La relación real está en film_category, que asigna una única categoría a cada película
-- (1.000 filas). Para obtener la categoría verdadera habría que hacer:
--     film JOIN film_category JOIN category
-- El CROSS JOIN solo es útil cuando SÍ quieres todas las combinaciones posibles porque
-- ninguna está registrada todavía, como en la consulta 63 (trabajadores x tiendas).

-- ---------------------------------------------------------------------------
-- 45. Encuentra los actores que han participado en películas de la categoría 'Action'.
-- ---------------------------------------------------------------------------
SELECT DISTINCT a.actor_id,
       a.first_name || ' ' || a.last_name AS actor
FROM actor         AS a
JOIN film_actor    AS fa ON fa.actor_id    = a.actor_id
JOIN film_category AS fc ON fc.film_id     = fa.film_id
JOIN category      AS c  ON c.category_id  = fc.category_id
WHERE c.name = 'Action'
ORDER BY actor;
-- DISTINCT imprescindible: un actor puede haber participado en varias películas de
-- acción y aparecería repetido una vez por película.

-- ---------------------------------------------------------------------------
-- 46. Encuentra todos los actores que no han participado en películas.
-- ---------------------------------------------------------------------------
SELECT a.actor_id,
       a.first_name || ' ' || a.last_name AS actor
FROM actor AS a
LEFT JOIN film_actor AS fa ON fa.actor_id = a.actor_id
WHERE fa.actor_id IS NULL;
-- Patrón "anti-join": LEFT JOIN + IS NULL devuelve lo que NO tiene pareja.
-- Resultado: 0 filas. Los 200 actores han participado en alguna película.
-- Alternativa equivalente:
--   SELECT * FROM actor WHERE actor_id NOT IN (SELECT actor_id FROM film_actor);

-- ---------------------------------------------------------------------------
-- 47. Selecciona el nombre de los actores y la cantidad de películas en las que han participado.
-- ---------------------------------------------------------------------------
SELECT a.first_name || ' ' || a.last_name AS actor,
       COUNT(fa.film_id) AS num_peliculas
FROM actor AS a
LEFT JOIN film_actor AS fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY num_peliculas DESC, actor;


-- ---------------------------------------------------------------------------
-- 48. Crea una vista llamada "actor_num_peliculas" que muestre los nombres de los actores y el número de películas en las que han participado.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW actor_num_peliculas AS
SELECT a.actor_id,
       a.first_name || ' ' || a.last_name AS actor,
       COUNT(fa.film_id) AS num_peliculas
FROM actor AS a
LEFT JOIN film_actor AS fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name;

-- Uso de la vista:
SELECT * FROM actor_num_peliculas ORDER BY num_peliculas DESC LIMIT 10;
-- Una vista es una consulta guardada con nombre: no almacena datos, se ejecuta cada vez
-- que se consulta, así que siempre refleja el estado actual de las tablas.


-- ---------------------------------------------------------------------------
-- 49. Calcula el número total de alquileres realizados por cada cliente.
-- ---------------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS cliente,
       COUNT(r.rental_id) AS num_alquileres
FROM customer AS c
LEFT JOIN rental AS r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY num_alquileres DESC;


-- ---------------------------------------------------------------------------
-- 50. Calcula la duración total de las películas en la categoría 'Action'.
-- ---------------------------------------------------------------------------
SELECT c.name AS categoria,
       COUNT(*)       AS num_peliculas,
       SUM(f.length)  AS duracion_total_min,
       ROUND(SUM(f.length) / 60.0, 1) AS duracion_total_horas
FROM film          AS f
JOIN film_category AS fc ON fc.film_id     = f.film_id
JOIN category      AS c  ON c.category_id  = fc.category_id
WHERE c.name = 'Action'
GROUP BY c.name;

-- ---------------------------------------------------------------------------
-- 51. Crea una tabla temporal llamada "cliente_rentas_temporal" para almacenar el total de alquileres por cliente.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE cliente_rentas_temporal AS
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS cliente,
       COUNT(r.rental_id) AS total_alquileres
FROM customer AS c
LEFT JOIN rental AS r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

SELECT * FROM cliente_rentas_temporal ORDER BY total_alquileres DESC LIMIT 10;          
-- Una tabla temporal SÍ almacena datos (a diferencia de una vista), pero solo existe
-- durante la sesión actual: al cerrar la conexión desaparece sola.
-- Ojo en DBeaver: si ejecutas el CREATE y el SELECT en editores distintos, el segundo
-- puede usar otra conexión y darte "relation does not exist". Ejecuta ambos en el mismo editor.

-- ---------------------------------------------------------------------------
-- 52. Crea una tabla temporal llamada "peliculas_alquiladas" que almacene las películas que han sido alquiladas al menos 10 veces.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE peliculas_alquiladas AS
SELECT f.film_id,
       f.title,
       COUNT(r.rental_id) AS veces_alquilada
FROM film         AS f
JOIN inventory    AS i ON i.film_id      = f.film_id
JOIN rental       AS r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title
HAVING COUNT(r.rental_id) >= 10;   -- "al menos 10" → >=, no >

SELECT * FROM peliculas_alquiladas ORDER BY veces_alquilada DESC;

-- ---------------------------------------------------------------------------
-- 53. Encuentra el título de las películas que han sido alquiladas por el cliente con el nombre 'Tammy Sanders' y que aún no se han devuelto. Ordena los resultados alfabéticamente por título de película.
-- ---------------------------------------------------------------------------
SELECT f.title
FROM rental      AS r
JOIN customer    AS c ON c.customer_id  = r.customer_id
JOIN inventory   AS i ON i.inventory_id = r.inventory_id
JOIN film        AS f ON f.film_id      = i.film_id
WHERE c.first_name ILIKE 'Tammy'
  AND c.last_name  ILIKE 'Sanders'
  AND r.return_date IS NULL    -- "aún no devuelta" = sin fecha de devolución
ORDER BY f.title;

-- ---------------------------------------------------------------------------
-- 54. Encuentra los nombres de los actores que han actuado en al menos una película que pertenece a la categoría 'Sci-Fi'. Ordena los resultados alfabéticamente por apellido.
-- ---------------------------------------------------------------------------
SELECT DISTINCT a.first_name, a.last_name
FROM actor         AS a
JOIN film_actor    AS fa ON fa.actor_id   = a.actor_id
JOIN film_category AS fc ON fc.film_id    = fa.film_id
JOIN category      AS c  ON c.category_id = fc.category_id
WHERE c.name = 'Sci-Fi'
ORDER BY a.last_name, a.first_name;

-- ---------------------------------------------------------------------------
-- 55. Encuentra el nombre y apellido de los actores que han actuado en películas que se alquilaron después de que la película 'Spartacus Cheaper' se alquilara por primera vez. Ordena los resultados alfabéticamente por apellido.
-- ---------------------------------------------------------------------------
SELECT DISTINCT a.first_name, a.last_name
FROM actor       AS a
JOIN film_actor  AS fa ON fa.actor_id    = a.actor_id
JOIN inventory   AS i  ON i.film_id      = fa.film_id
JOIN rental      AS r  ON r.inventory_id = i.inventory_id
WHERE r.rental_date > (
        -- subconsulta escalar: primer alquiler registrado de 'Spartacus Cheaper'
        SELECT MIN(r2.rental_date)
        FROM rental    AS r2
        JOIN inventory AS i2 ON i2.inventory_id = r2.inventory_id
        JOIN film      AS f2 ON f2.film_id      = i2.film_id
        WHERE f2.title ILIKE 'Spartacus Cheaper'
      )
ORDER BY a.last_name, a.first_name;
-- Resultado: los 200 actores. No es un error: el primer alquiler de esa película es del
-- 8 de julio de 2005, muy al principio del histórico, así que 11.449 de los 16.044
-- alquileres son posteriores y cubren 958 películas. El filtro apenas restringe nada.


-- ---------------------------------------------------------------------------
-- 56. Encuentra el nombre y apellido de los actores que no han actuado en ninguna película de la categoría 'Music'.
-- ---------------------------------------------------------------------------
SELECT a.first_name, a.last_name
FROM actor AS a
WHERE a.actor_id NOT IN (
        SELECT fa.actor_id
        FROM film_actor    AS fa
        JOIN film_category AS fc ON fc.film_id     = fa.film_id
        JOIN category      AS c  ON c.category_id  = fc.category_id
        WHERE c.name = 'Music'
      )
ORDER BY a.last_name, a.first_name;
-- NOT IN es seguro aquí porque fa.actor_id nunca es NULL. Si pudiera serlo, la consulta
-- devolvería 0 filas siempre, y habría que usar NOT EXISTS.

-- ---------------------------------------------------------------------------
-- 57. Encuentra el título de todas las películas que fueron alquiladas por más de 8 días.
-- ---------------------------------------------------------------------------
SELECT DISTINCT f.title
FROM rental    AS r
JOIN inventory AS i ON i.inventory_id = r.inventory_id
JOIN film      AS f ON f.film_id      = i.film_id
WHERE r.return_date - r.rental_date > INTERVAL '8 days'
ORDER BY f.title;
-- Se compara la duración real del alquiler, no el rental_duration contratado.
-- Los alquileres sin devolver (return_date NULL) quedan fuera automáticamente,
-- porque cualquier operación con NULL da NULL y no cumple la condición.


-- ---------------------------------------------------------------------------
-- 58. Encuentra el título de todas las películas que son de la misma categoría que 'Animation'.
-- ---------------------------------------------------------------------------
SELECT f.title,
       c.name AS categoria
FROM film          AS f
JOIN film_category AS fc ON fc.film_id     = f.film_id
JOIN category      AS c  ON c.category_id  = fc.category_id
WHERE c.name = 'Animation'
ORDER BY f.title;


-- ---------------------------------------------------------------------------
-- 59. Encuentra los nombres de las películas que tienen la misma duración que la película con el título 'Dancing Fever'. Ordena los resultados alfabéticamente por título de película.
-- ---------------------------------------------------------------------------
SELECT title, length AS duracion_min
FROM film
WHERE length = (SELECT length FROM film WHERE title ILIKE 'Dancing Fever')
  AND title NOT ILIKE 'Dancing Fever'   -- excluimos la propia película de referencia
ORDER BY title;

-- ---------------------------------------------------------------------------
-- 60. Encuentra los nombres de los clientes que han alquilado al menos 7 películas distintas. Ordena los resultados alfabéticamente por apellido.
-- ---------------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(DISTINCT i.film_id) AS peliculas_distintas
FROM customer  AS c
JOIN rental    AS r ON r.customer_id  = c.customer_id
JOIN inventory AS i ON i.inventory_id = r.inventory_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT i.film_id) >= 7
ORDER BY c.last_name, c.first_name;
-- COUNT(DISTINCT i.film_id) y no COUNT(*): un cliente puede alquilar dos copias distintas
-- de la misma película, o la misma película dos veces, y eso cuenta como una sola.

-- ---------------------------------------------------------------------------
-- 61. Encuentra la cantidad total de películas alquiladas por categoría y muestra el nombre de la categoría junto con el recuento de alquileres.
-- ---------------------------------------------------------------------------
SELECT c.name AS categoria,
       COUNT(r.rental_id) AS num_alquileres
FROM category      AS c
JOIN film_category AS fc ON fc.category_id = c.category_id
JOIN film          AS f  ON f.film_id      = fc.film_id
JOIN inventory     AS i  ON i.film_id      = f.film_id
JOIN rental        AS r  ON r.inventory_id = i.inventory_id
GROUP BY c.name
ORDER BY num_alquileres DESC;
-- La cadena completa category → film_category → film → inventory → rental es obligatoria:
-- se cuentan alquileres reales, no títulos del catálogo.


-- ---------------------------------------------------------------------------
-- 62. Encuentra el número de películas por categoría estrenadas en 2006.
-- ---------------------------------------------------------------------------
SELECT c.name AS categoria,
       COUNT(*) AS num_peliculas
FROM category      AS c
JOIN film_category AS fc ON fc.category_id = c.category_id
JOIN film          AS f  ON f.film_id      = fc.film_id
WHERE f.release_year = 2006
GROUP BY c.name
ORDER BY num_peliculas DESC;
-- Nota: el filtro no descarta nada, porque las 1.000 películas de la BBDD son de 2006.
-- Comprobación:  SELECT DISTINCT release_year FROM film;  → un único valor, 2006.
-- El resultado coincide por tanto con el número total de películas por categoría.

-- ---------------------------------------------------------------------------
-- 63. Obtén todas las combinaciones posibles de trabajadores con las tiendas que tenemos.
-- ---------------------------------------------------------------------------
SELECT s.staff_id,
       s.first_name || ' ' || s.last_name AS trabajador,
       st.store_id,
       a.address AS direccion_tienda
FROM staff AS s
CROSS JOIN store AS st
JOIN address AS a ON a.address_id = st.address_id
ORDER BY s.staff_id, st.store_id;
-- Aquí el CROSS JOIN sí aporta valor, al contrario que en la consulta 44: el enunciado
-- pide explícitamente TODAS las combinaciones posibles (2 trabajadores x 2 tiendas = 4),
-- no las asignaciones reales. Las reales serían:  WHERE s.store_id = st.store_id  → 2 filas.


-- ---------------------------------------------------------------------------
-- 64. Encuentra la cantidad total de películas alquiladas por cada cliente y muestra el ID del cliente, su nombre y apellido junto con la cantidad de películas alquiladas.
-- ---------------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(r.rental_id) AS peliculas_alquiladas
FROM customer AS c
LEFT JOIN rental AS r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY peliculas_alquiladas DESC, c.last_name; 

