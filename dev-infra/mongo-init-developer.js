// Crea el usuario DEV_USER con privilegios globales (root).
// Se ejecuta solo en la primera inicialización (volumen vacío), con la autenticación desactivada.
const devUser = process.env.DEV_USER;
const devPassword = process.env.DEV_PASSWORD;
const adminDb = db.getSiblingDB('admin');

if (!adminDb.getUser(devUser)) {
  adminDb.createUser({
    user: devUser,
    pwd: devPassword,
    roles: [{ role: 'root', db: 'admin' }]
  });
}
