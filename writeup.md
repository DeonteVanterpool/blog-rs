## Models
All data models are in src/models. These models are used to represent the data structures used throughout the application. Each model is defined in its own file, which helps maintain clarity and organization.

## Services
All services are in src/services. These services contain most of the business logic. Many services such as the FileSystemService also have an interface in the same file. This is to allow for easier mocking in tests. The concrete implementation is in the same file as the interface to allow for easy access (without codesearch).

## Handlers
All handlers are in src/handlers.rs. Handlers are responsible for processing requests and returning responses.

## Decisions
Caddy was mainly chosen over nginx so that we don't have to worry about maintaining SSL certificates. I didn't want to have to fiddle with docker and getting certbot to automatically renew certificates, as well as mounting them to the correct docker volume. Caddy made this process much simpler and maintainable.
