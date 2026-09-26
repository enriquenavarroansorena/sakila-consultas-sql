# 🎬 Consultas SQL sobre la base de datos Sakila

Resolución de las 64 consultas del DataProject "Lógica: Consultas de SQL" sobre **Sakila**, la base de
datos de ejemplo de una tienda de alquiler de películas, usando **PostgreSQL** y **DBeaver**.

## 📖 Descripción

El objetivo del proyecto es demostrar el manejo de SQL en sus distintos niveles: consultas sobre una
sola tabla, relaciones entre tablas con los distintos tipos de `JOIN`, subconsultas, vistas y
estructuras de datos temporales, aplicando buenas prácticas de escritura y, sobre todo,
**entendiendo el resultado que devuelve cada consulta**.

No se trata solo de que la consulta se ejecute sin error: varias de ellas devuelven resultados que hay
que interpretar con cuidado, y esas interpretaciones están comentadas en el propio archivo SQL.

## 🗂 Estructura del proyecto

```
├── bbdd/
│   └── BBDD_Proyecto_shakila_sinuser.sql   # Script de creación de la BBDD (proporcionado)
├── consultas/
│   └── consultas_sakila.sql                # Las 64 consultas resueltas y comentadas
├── images/
│   └── esquema_bbdd.png                    # Diagrama entidad-relación
└── README.md
```

## 🗃 La base de datos

**Sakila** modela el negocio de una cadena de videoclubs: catálogo de películas, copias físicas en dos
tiendas, clientes, alquileres, pagos y empleados.

![Esquema de la base de datos Sakila](images/esquema_bbdd.png)

### Volumen de datos

| Tabla | Filas | | Tabla | Filas |
|---|---|---|---|---|
| film | 1.000 | | rental | 16.044 |
| actor | 200 | | payment | 16.049 |
| customer | 599 | | inventory | 4.581 |
| category | 16 | | film_actor | 5.462 |
| film_category | 1.000 | | | |

### Claves para entender el modelo

- **Una película no se alquila directamente.** Lo que se alquila es una **copia física** concreta, que
  vive en `inventory`. Por eso, para unir el catálogo con el negocio hay que recorrer siempre el camino
  `film → inventory → rental → payment`.
- **Cada película pertenece a una sola categoría**: `film_category` tiene exactamente 1.000 filas, las
  mismas que `film`. En cambio `film_actor` tiene 5.462, unos 5,5 actores por película, así que un
  `JOIN` con actores **sí multiplica filas** y hay que tenerlo en cuenta al contar.
- `film` se relaciona **dos veces** con `language`: por `language_id` (idioma de la película) y por
  `original_language_id` (idioma original).

## 🛠 Cómo reproducir el entorno

1. Instalar **PostgreSQL** y **DBeaver**, y crear una conexión a `localhost:5432` con el usuario `postgres`.
2. Crear la base de datos:

```sql
CREATE DATABASE sakila;
```

3. Abrir `bbdd/BBDD_Proyecto_shakila_sinuser.sql` en DBeaver, **asignarle la base de datos `sakila`** y
   ejecutarlo como script completo (`Alt + X`). El dump no incluye `CREATE DATABASE`, de ahí el paso anterior.
4. Comprobar la carga:

```sql
SELECT COUNT(*) FROM film;   -- 1000
SELECT COUNT(*) FROM actor;  -- 200
```

5. Abrir `consultas/consultas_sakila.sql` y ejecutar cada consulta por separado con `Ctrl + Enter`.

## ✍️ Convenciones seguidas en el SQL

- Palabras clave en MAYÚSCULAS e identificadores en minúscula.
- Cada consulta precedida de **su número y su enunciado literal** como comentario.
- Alias cortos y con sentido (`f` para film, `a` para actor, `c` para customer...).
- `JOIN ... ON` explícito; nunca joins implícitos separados por comas.
- Una cláusula por línea y sangría consistente.
- Comentarios adicionales en las consultas cuyo resultado requiere interpretación.

## 📊 Informe del análisis

Las 64 consultas, además de ejercitar SQL, dibujan el retrato de un negocio. Esto es lo que cuentan.

### El negocio en cifras

| Indicador | Valor |
|---|---|
| Ingresos totales | **67.416,51 $** en 16.049 pagos |
| Ticket medio | 4,20 $ (desviación típica 2,36) |
| Alquileres registrados | 16.044 |
| Clientes | 599, con una media de **26,8 alquileres** cada uno (de 12 a 46) |
| Catálogo | 1.000 películas en 16 categorías |
| Copias físicas | 4.581, repartidas en 2 tiendas |
| Plantilla | 2 empleados |

### Qué revelan los datos

**1. El catálogo está deliberadamente equilibrado.** Las 16 categorías tienen entre 51 y 74 películas, y
los tres precios de alquiler (0,99 · 2,99 · 4,99 $) se reparten casi en tercios: 341, 323 y 336 películas.
No hay una apuesta por ningún género ni una estrategia de precios diferenciada por contenido.

**2. La demanda también es plana.** El género más alquilado (Sports, 1.179 alquileres) supera al menos
alquilado (Music, 830) en apenas un 42%, con los 16 géneros muy agrupados. En un videoclub real se
esperaría una distribución mucho más desigual, con unos pocos títulos acaparando la demanda. Es el primer
indicio de que **los datos de alquiler están generados sintéticamente**, no observados.

**3. El histórico es mucho más corto de lo que parece.** Aunque hay 16.044 alquileres, se concentran en
41 días de 2005 (mayo a agosto) más un único día de febrero de 2006 con 182 registros:

| Mes | Alquileres |
|---|---|
| 2005-05 | 1.156 |
| 2005-06 | 2.311 |
| **2005-07** | **6.709** |
| 2005-08 | 5.686 |
| 2006-02 | 182 |

La caída de agosto a febrero **no es una caída del negocio**: es el final de los datos. Cualquier análisis
de tendencia sobre esta base sería engañoso.

**4. Uno de cada seis alquileres se devuelve tarde.** El plazo contratado (`film.rental_duration`) va de 3
a 7 días, con una media de 4,99. Sin embargo, **2.664 alquileres superaron los 8 días**, afectando a 876
títulos distintos. Es la métrica con más recorrido comercial de todo el conjunto: son recargos por demora
o, según la política, pérdida de rotación de las copias.

**5. Hay stock muerto y stock ocioso.** 42 películas del catálogo **no tienen ninguna copia física**, así
que no se pueden alquilar aunque figuren en el catálogo. Y de las 4.581 copias existentes, una no se ha
alquilado nunca. Ambos casos solo salen a la luz con `LEFT`/`FULL OUTER JOIN`: con un `INNER JOIN`
desaparecerían silenciosamente del informe.

**6. Los clientes están muy igualados.** El que más ha gastado (id 526) suma 221,55 $ y el más activo
(id 148) acumula 46 alquileres, frente a una media de 26,8. No existe el cliente VIP que concentra el
negocio, lo que refuerza la idea de datos generados artificialmente.

### Consultas cuyo resultado hay que saber interpretar

El enunciado avisaba de que no bastaba con que las consultas funcionasen. Estas seis son el ejemplo:

| # | Resultado | Por qué |
|---|---|---|
| 4 | **0 filas** | `original_language_id` es `NULL` en las 1.000 películas, y en SQL `NULL` no es igual a nada, ni siquiera a sí mismo. El dato nunca se registró: la pregunta no puede responderse |
| 11 | Depende del desempate | Los 182 últimos alquileres comparten fecha y hora exactas, así que "el antepenúltimo" no está definido sin un criterio adicional (`rental_id`) |
| 44 | 16.000 filas | El `CROSS JOIN` inventa relaciones falsas: afirma que cada película pertenece a las 16 categorías. La relación real vive en `film_category` |
| 55 | Los 200 actores | El primer alquiler de *Spartacus Cheaper* es del 8 de julio de 2005, tan temprano que 11.449 de los 16.044 alquileres son posteriores. El filtro no discrimina |
| 60 | Los 599 clientes | El umbral de 7 películas distintas lo supera incluso el cliente menos activo, que tiene 12 |
| 62 | Sin efecto el filtro | Las 1.000 películas son de `release_year` 2006, así que filtrar por ese año no descarta nada |

Una consulta que devuelve el 100% de los registros no está necesariamente mal: puede que el filtro no
aporte información. Distinguir entre las dos situaciones es el verdadero ejercicio.

### Decisiones técnicas destacables

- **`ILIKE` en lugar de `LIKE`.** Los datos de `actor`, `customer` y `film.title` están **en mayúsculas**
  (`CUBA ALLEN`, `ACADEMY DINOSAUR`), mientras que `category.name` usa mayúscula inicial (`Comedy`).
  Buscar `'Allen'` con `LIKE` habría devuelto 0 filas en lugar de 3.
- **`COUNT(columna)` frente a `COUNT(*)` en los `LEFT JOIN`.** En la consulta 29, `COUNT(*)` habría contado
  1 para las 42 películas sin copias, porque la fila existe aunque venga con `NULL`. `COUNT(i.inventory_id)`
  ignora los nulos y devuelve el 0 correcto.
- **`COUNT(DISTINCT ...)` en la 60.** Un cliente puede alquilar dos copias distintas del mismo título, o el
  mismo título dos veces; el enunciado pedía películas *distintas*.
- **Anti-join (`LEFT JOIN ... IS NULL`)** en la 46 para buscar lo que no existe, y `NOT IN` en la 56.
- **`HAVING` frente a `WHERE`**: `WHERE` filtra filas antes de agrupar, `HAVING` filtra grupos ya agregados.
  Necesario en las consultas 20, 28, 52 y 60.
- **Vista frente a tabla temporal**: la vista (consulta 48) no almacena datos y se recalcula en cada
  consulta; las tablas temporales (51 y 52) sí los almacenan, pero solo durante la sesión.

### ⚠️ Limitaciones de los datos

1. **El histórico cubre apenas 3 meses reales** (mayo-agosto de 2005), más un día suelto de 2006.
2. **Todas las películas son de 2006**, lo que impide cualquier análisis por antigüedad del catálogo.
3. **`original_language_id` está vacío** en toda la tabla.
4. **La distribución de la demanda es artificialmente uniforme**, así que las conclusiones de negocio son
   ilustrativas, no extrapolables a un videoclub real.

## 🔄 Próximos pasos

- Analizar la rentabilidad por copia física: qué unidades de `inventory` amortizan su `replacement_cost`
  y cuáles no rotan.
- Estudiar los 2.664 alquileres con retraso: si se concentran en ciertos títulos, categorías o clientes.
- Cruzar clientes con `address → city → country` para ver la distribución geográfica de la demanda.
- Optimizar las consultas más pesadas con `EXPLAIN ANALYZE` y valorar índices sobre `rental.rental_date`
  e `inventory.film_id`.

## ✒️ Autor

- Enrique Navarro — [@enriquenavarroansorena](https://github.com/enriquenavarroansorena)

Base de datos Sakila, utilizada con fines formativos.
