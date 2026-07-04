/// Lifecycle states returned by the household invitation RPCs.
///
/// `expired` is derived by the backend when a pending invitation is inspected;
/// it is not persisted as a database status.
enum HouseholdInvitationStatus { pending, accepted, cancelled, expired }
