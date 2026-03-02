# Ejercicios de Flex & Bison - Capítulo 2

Este documento explica las soluciones implementadas para los ejercicios del Capítulo 2 del libro *Flex & Bison* de John Levine, enfocados en la optimización de escaneo y el manejo dinámico de tablas de símbolos.

---

### Ejercicio 1: Optimización de Coincidencia de Texto

#### Pregunta original (English)
**Example 2-3 matches characters one at a time. Why doesn’t it match them a line at a time with a pattern like `^.*\n`? Suggest a pattern or combination of patterns that would match larger chunks of text, keeping in mind the reason `^.*` won’t work.**

#### Traducción
El Ejemplo 2-3 coincide con los caracteres uno a la vez. ¿Por qué no coincide con una línea a la vez con un patrón como `^.*\n`? Sugiere un patrón o combinación de patrones que coincida con trozos más grandes de texto, teniendo en cuenta por qué `^.*` no funcionará.

#### Explicación de la solución
- **Problema:** El patrón `^.*\n` es problemático porque el ancla `^` solo funciona al inicio de la línea y el punto `.` no captura saltos de línea. Además, una regla tan general podría "comerse" accidentalmente directivas importantes como `#include` antes de que sus reglas específicas puedan actuar.
- **Modificación:** Se implementó el patrón `[^\n#]+`. Esto permite que Flex capture bloques grandes de texto de una sola vez (aumentando la eficiencia) pero se detenga inmediatamente si encuentra un salto de línea o un símbolo `#`, permitiendo que las reglas de conteo de líneas y de inclusión de archivos funcionen correctamente.

#### Cómo se ejecuta
1. Generar el analizador: `flex ejercicio1.l`
2. Compilar el código C: `gcc lex.yy.c -o ejercicio1 -lfl`
3. Ejecutar con un archivo de prueba: `./ejercicio1 prueba.txt`

---

### Ejercicio 2: Concordancia Insensible a Mayúsculas

#### Pregunta original (English)
**The concordance program treats upper- and lowercase text separately. Modify it to handle them together. You can do this without making extra copies of the words. In `symhash()`, use `tolower` to hash lowercase versions of the characters, and use `strcasecmp()` to compare words.**

#### Traducción
El programa de concordancia trata mayúsculas y minúsculas por separado. Modifícalo para que las trate juntas sin hacer copias extra de las palabras. En `symhash()`, usa `tolower()` para calcular el hash y `strcasecmp()` para comparar palabras.

#### Explicación de la solución
- **Modificación:** Se modificó la lógica de procesamiento de palabras para que, antes de almacenar cualquier referencia en el archivo temporal o realizar comparaciones, cada carácter de la palabra sea convertido a minúsculas mediante la función `tolower()`.
- **Resultado:** Esto garantiza que palabras como "Hola", "HOLA" y "hola" sean tratadas como la misma entidad en el reporte final, unificando las referencias sin necesidad de duplicar datos en memoria.

#### Cómo se ejecuta
1. Generar el analizador: `flex ejercicio2.l`
2. Compilar el código C: `gcc lex.yy.c -o ejercicio2 -lfl`
3. Ejecutar con un archivo de prueba: `./ejercicio2 prueba.txt`

---

### Ejercicio 3: Tabla de Símbolos Dinámica (Chaining)

#### Pregunta original (English)
**The symbol table routine in the concordance and cross-referencer programs uses a fixed-size symbol table and dies if it fills up. Modify the routine so it doesn’t do that. The two standard techniques to allow variable-sized hash tables are chaining and rehashing. [...] Both techniques work, but one would make it a lot messier to produce the cross-reference. Which one? Why?**

#### Traducción
La rutina de la tabla de símbolos usa un tamaño fijo y falla si se llena. Modifícala para que no falle usando encadenamiento (chaining) o rehashing. Ambas técnicas funcionan, pero una hace que sea mucho más complicado producir la referencia cruzada. ¿Cuál? ¿Por qué?

#### Explicación de la solución
- **Modificación:** Se rediseñó la tabla de símbolos para utilizar **Encadenamiento (Chaining)**. La tabla hash ahora es un arreglo de punteros a listas ligadas. Cuando ocurre una colisión o se encuentra una palabra nueva, se asigna memoria dinámicamente con `malloc()` y se inserta en la lista correspondiente.
- **Respuesta Teórica:** El **Rehashing** sería más "sucio" o complicado (messier) para este programa. Esto se debe a que, al redimensionar la tabla, todas las posiciones de los símbolos cambian, lo que dificulta mantener un orden coherente para el reporte. El encadenamiento permite que la estructura base sea estable mientras las listas crecen según sea necesario.
- **Corrección de Memoria:** Se implementó el uso de `strdup()` para los nombres de archivos en cada referencia, evitando errores de lectura de memoria (caracteres extraños) al cerrar archivos anidados.

#### Cómo se ejecuta
1. Generar el analizador: `flex ejercicio3.l`
2. Compilar el código C: `gcc lex.yy.c -o ejercicio3 -lfl`
3. Ejecutar con un archivo de prueba: `./ejercicio3 prueba.txt`