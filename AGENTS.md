# NoveLib revision and release records

- For every user-visible app change, update the current unreleased patch notes under source/app/assets/release_notes/v<VERSION>.txt in the same task.
- Record implemented behavior only. Clearly distinguish server prerequisites, disabled features, known limitations, and unimplemented requests.
- Keep prior version notes. Never rewrite a released version to describe later changes.
- Keep pubspec.yaml, the release-notes dialog version, and the build version consistent.
- Each release ZIP must include its matching PATCH-NOTES text file. Missing notes must stop packaging.
- Record test results and remaining release checks in docs/CHANGELOG.md. Do not call a build publicly released merely because local packaging succeeded.
