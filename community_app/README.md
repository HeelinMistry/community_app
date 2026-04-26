# Community Project

## App Notes
- To be added

## Developer Notes
### SwiftLint Usage (To be added)
We use SwiftLint to enforce style. It runs automatically during build phases.
- **To fix simple violations:** run `swiftlint --fix` in the root directory.
- **Rules:** Defined in `.swiftlint.yml`.

### Frameworks
We use packages to ensure UI Layer -> Core Layer -> Data Layer -> Repository/Cache
- Common
- Core
- Data
- UI
We use UseCase to communicate from UI to Core

### Documentation
CMD+^+shift+D (Build Xcode docc)

API Documentation is auto-generated and hosted via GitHub Pages

## Project Structure
The Core defines the RepositoryProtocol. Data then implements that protocol. The rest of the app (like UI) only ever talks to the Core Protocols. This means you could swap Data for a MockData package or a LocalDatabaseData.

Mappers/ folder in Data. This is the most critical part. It takes raw API DTOs (Data Transfer Objects) from the web and converts them into the "Pure" models found in Core.

By keeping Core independent, you ensure that the UI doesn't accidentally depend on the Networking library (URLSession/AlamoFire) and the Networking library doesn't depend on SwiftUI.

Caching is done storing to a local file on device, implemented so this can implement all 3 [swiftdata, coredata] and each can be used interchangeable
``
```
- community_app/
- App/
    - DependencyContainer.swift
    - CommunitySwiftApp.swift
- Theming/
    - CommunityTheme.swift
- Frameworks/
    - UI/
        - UI/
            - Theming/
                - Assets.swift
                - Theme.swift
            - StyledComponents/
                - PrimaryTextInput.swift
                - PrimaryButton.swift
                - BrandLogo.swift
                - SecondaryButton.swift
            - Views/
                - LoginView.swift
            - UI.docc/
                - UI.md
```
``

