export interface Theme {
    name: string;
    properties: any;
    dark: boolean;
}

export const light: Theme = {
    name: 'light',
    properties: {
        '--background-default': '#ffffff',
        '--background-default-dim': '#ffffffd0',
        '--background-secondary': '#8da9c440',

        '--background-button': '#ffffff',
        '--color-button': '#00212f',

        '--font-primary': '#134074',
        '--font-secondary': '#8da9c4',
        '--font-tertiary': '#13315c',

        '--error-default': '#EF3E36',
        '--error-dark': '#800600',
        '--error-light': '#FFCECC',
    },
    dark: false
};

export const dark: Theme = {
    name: 'dark',
    properties: {
        '--background-default': '#00212f',
        '--background-default-dim': '#00212fd0',
        '--background-secondary': '#284555',

        '--background-button': '#ffffff',
        '--color-button': '#00212f',

        '--font-primary': '#b9def5',
        '--font-secondary': '#ffffff',
        '--font-tertiary': '#009cff',

        '--error-default': '#EF3E36',
        '--error-dark': '#800600',
        '--error-light': '#FFCECC',
    },
    dark: true
};
