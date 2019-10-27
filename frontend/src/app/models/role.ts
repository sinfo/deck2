export enum RoleType {
    MEMBER = 'MEMBER',
    TEAM_LEADER = 'TEAMLEADER',
    COORDINATOR = 'COORDINATOR',
    ADMIN = 'ADMIN',
}

export class Role {
    role: RoleType;
}

export function CoordinatorAccessLevel(role: Role) {
    return role.role === 'ADMIN' || role.role === 'COORDINATOR';
}

export function RoleValue(role: RoleType): number {
    switch (role) {
        case RoleType.ADMIN:
            return 0;
        case RoleType.COORDINATOR:
            return 1;
        case RoleType.TEAM_LEADER:
            return 2;
        case RoleType.MEMBER:
            return 3;
        default:
            return 4;
    }
}

export function RoleComparator(r1: RoleType, r2: RoleType) {
    const v1 = RoleValue(r1);
    const v2 = RoleValue(r2);

    if (v1 < v2) { return -1; }
    if (v2 < v1) { return 1; }
    return 0;
}
