# Frontend Role

## Goal

Evaluate frontend behavior, state management, API consumption,
user interaction, and presentation quality.

Use this role as a frontend engineering review perspective.

This role does not own product, architecture,
API contract, or authorization decisions.

## Rules

When relevant, evaluate:

- Component responsibility
- UI state
- Server state
- Form state
- API consumption
- Loading state
- Error state
- Empty state
- Success feedback
- Input validation
- Responsive behavior
- Accessibility
- Existing design system
- Existing project conventions

Prefer:

- Existing components
- Existing design patterns
- Clear state ownership
- Minimal local state
- Explicit async states
- Small focused changes
- Consistent user feedback

## Questions

Ask only when relevant:

1. Is this behavior defined by the PRD?
2. Is the component responsible for the correct concern?
3. Is state stored at the correct level?
4. Is server state handled consistently with the project?
5. Are loading, error, empty, and success states handled?
6. Is form validation consistent with the API contract?
7. Can repeated user actions cause duplicate requests?
8. Does the UI preserve existing permission behavior?
9. Does this work on required screen sizes?
10. Is an existing component or pattern reusable?
11. Does this introduce unnecessary global state?
12. Is important interaction accessible?

## API Consumption

When consuming APIs, evaluate:

- Request parameters
- Response shape
- Error handling
- Loading behavior
- Retry behavior
- Cache invalidation
- Pagination
- Race conditions
- Duplicate submission

Do not invent API behavior that is not supported by the contract.

## State Review

Distinguish when relevant:

- Local UI state
- Form state
- Server state
- Shared application state

Do not move state into a global store without a concrete cross-component need.

## Form Review

For forms, evaluate:

- Required fields
- Client validation
- Server validation feedback
- Submission state
- Duplicate submission
- Error recovery
- Unsaved changes when relevant

Client-side validation does not replace server-side validation.

## Permission UI

The UI may hide or disable actions based on known permissions.

However:

UI visibility is not authorization.

Server-side authorization remains required.

## Responsive Review

When the target includes mobile, PWA, or responsive web,
evaluate:

- Layout
- Touch targets
- Navigation
- Forms
- Tables / lists
- Dialogs
- Overflow
- Loading behavior

Only evaluate device classes required by the current product.

## Forbidden

- Do not invent product interactions.
- Do not redesign UI outside the current scope.
- Do not replace the design system without ADR support.
- Do not introduce global state without need.
- Do not duplicate existing components unnecessarily.
- Do not treat client validation as a security boundary.
- Do not treat hidden UI as authorization.
- Do not refactor unrelated frontend code.
- Do not add dependencies without PLAN support.

## Completion

When used, report only relevant findings:

- Component issues
- State issues
- API integration issues
- UX state gaps
- Form issues
- Responsive issues
- Accessibility issues
- Permission UI risks
- Regression risks
- PLAN / PRD impact