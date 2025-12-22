// cp novnc_setup/page.tsx .devcontainer/novnc/src/app/page.tsx

import { readServices } from "@/lib/server/services";

export const dynamic = "force-dynamic"

type Service = {
    version: string;
    port: number;
    resources?: string;
}
type Services = Record<string, Service>;


export function BlenderService({ service, port, version, resources}: Service & { service: string }) {
    return (
        <a
            href={`/${service}`}
            aria-label={`${service}`}
        >
            {`${service} (version: ${version} ${resources ? `, resources: ${resources}` : ''})`}
        </a>
    );
}

export default async function Page() {
    const services = await readServices();
    const dict = services as Services;
    return (
        <div style={{ display: 'flex', flexDirection: 'column' }}>
            {Object.entries(dict).map(([service, data]) => (
                <BlenderService key={service} service={service} {...data} />
            ))}
        </div>
    );
}