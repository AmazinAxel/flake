// @ts-nocheck TODO fix types

declare const SRC: string;

declare module "inline:*" {
    const content: string;
    export default content;
}

declare module "*.css" {
    const content: string;
    export default content;
}
