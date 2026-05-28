# README

Aplicación backend

## Desiciones Técnicas Generales

- Se utilizó la arquitectura estándar de Ruby, con separación entre controladores y servicios (casos de uso). 
- Los controladores sólo reciben y validan datos del cliente y luego ejecutan los servicios.
- Los servicios dependen de abstracciones y del orm nativo de Ruby, o sea, ActiveRecord.
- 