const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');

async function run() {
  const projectId = 'cancionero-7cd85';
  const rules = fs.readFileSync('firestore.rules', 'utf8');

  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules }
  });

  // Usuario autenticado 'alice'
  const alice = testEnv.authenticatedContext('alice').firestore();

  // 1) Alice crea una solicitud hacia bob -> debe tener éxito
  await assertSucceeds(
    alice.doc('usuarios/bob/solicitudes/alice').set({
      fromUid: 'alice',
      fromNombre: 'Alice'
    })
  );

  // 2) Alice intenta fijar enviado_en -> debe fallar
  await assertFails(
    alice.doc('usuarios/bob/solicitudes/alice2').set({
      fromUid: 'alice',
      fromNombre: 'Alice',
      enviado_en: 123
    })
  );

  // 3) Bob (destinatario) lee sus solicitudes -> debe tener éxito
  const bob = testEnv.authenticatedContext('bob').firestore();
  await assertSucceeds(
    bob.doc('usuarios/bob/solicitudes/alice').get()
  );

  console.log('Pruebas completadas.');
  await testEnv.cleanup();
}

run().catch(e => { console.error(e); process.exit(1); });
