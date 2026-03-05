Task Manager

Prueba tecnica en Flutter para gestionar tareas. Consume una API REST y usa Riverpod para el estado.


Cómo ejecutar

1. Clona o abre el proyecto y en la raíz ejecuta:

   flutter pub get

2. Crea un archivo .env en la raíz del proyecto (mismo nivel que pubspec.yaml) con estas variables:

   BASE_URL=https://ecsdevapi.nextline.mx/vdev/tasks-challenge
   AUTH_TOKEN=Token_Enviado
   TASK_TOKEN=Yahir_2026

   Sin el .env la app no arranca porque necesita la URL base y los tokens para la API.

3. Ejecuta la app:

   flutter run

Estructura del proyecto

- lib/main.dart – Punto de entrada, configuración de tema y locale (es).
- lib/api/ – Cliente HTTP (Dio) para GET/POST/PUT/DELETE de tareas.
- lib/models/ – Modelo Task y parseo desde JSON.
- lib/state/ – TaskNotifier (Riverpod): lista de tareas, fetch, crear, actualizar, eliminar y merge con lo que ya está en estado cuando la API devuelve poco (p. ej. al recargar).
- lib/screens/ – Lista de tareas y pantalla de detalle.
- lib/widgets/ – Tarjeta de tarea, ítem de lista, bottom sheet del formulario crear/editar.

Las pantallas leen el estado con ref.watch(taskNotifierProvider) y las acciones llaman al notifier (fetch, create, update, delete).


Decisiones técnicas

- Riverpod para estado global de la lista; así se evita pasar callbacks en cadena y la lista/detalle/formulario se mantienen sincronizados.
- Dio para las peticiones; el API devuelve a veces solo campos básicos, por eso en el notifier se hace merge con lo que ya está en estado (description, tags, comments) para no perderlo al recargar.
- Idioma español en MaterialApp para que el date picker y textos del sistema salgan en español.
