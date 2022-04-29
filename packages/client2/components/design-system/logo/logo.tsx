import goldfinchLogoPng from "./goldfinch-logo.png";
import GoldfinchLogoSvg from "./goldfinch-logo.svg";

export const goldfinchLogoPngUrl = goldfinchLogoPng.src;

interface GoldfinchLogoProps {
  width?: number;
  height?: number;
  className?: string;
}

export function GoldfinchLogo(props: GoldfinchLogoProps) {
  return <GoldfinchLogoSvg {...props} />;
}
