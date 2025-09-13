// Minimal TypeScript stub for future enhancements (no build required here)
export interface SceneAssets { dem_cog?: string; heightmap?: string; vectors?: string; scene?: string }
export interface SceneManifest { version: string; crs: string; origin: {lat:number;lon:number;elevation_m:number}; bounds?: {min:[number,number]; max:[number,number]}; assets: SceneAssets }

