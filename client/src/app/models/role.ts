export class Role {
    role: String;
}

export function CoordinatorAccessLevel(role: Role) {
    return role.role === 'ADMIN' || role.role === 'COORDINATOR';
}
