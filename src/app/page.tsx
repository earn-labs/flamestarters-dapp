import AccountInfo from "@/components/accountInfo/accountInfo";
import CollectionInfo from "@/components/collectionInfo/collectionInfo";
import Minter from "@/components/minter/minter";
import Navbar from "@/components/navigation/navbar";
import Nfts from "@/components/nfts/nfts";
import About from "@/components/about/about";

export default function Home() {
  return (
    <main className="flex h-screen flex-col justify-items-stretch bg-black bg-scroll p-4 text-black bg-blend-darken">
      <div className="mx-auto h-full w-full flex-col items-center justify-between xl:w-5/6">
        <Navbar></Navbar>
        {/* <h1 className="my-8 h-10 text-center text-xl font-bold uppercase drop-shadow-text xs:text-2xl md:text-3xl"></h1> */}
        <div className="mt-4 grid w-full grid-cols-1 justify-between justify-items-stretch gap-4 md:grid-cols-[25%_30%_40%]">
          <div className="flex h-full w-full flex-col justify-stretch">
            <CollectionInfo></CollectionInfo>
            <AccountInfo></AccountInfo>
          </div>

          <Minter></Minter>
          <div className="flex h-full w-full flex-col justify-stretch">
            <Nfts></Nfts>
            <About></About>
          </div>
        </div>
      </div>
    </main>
  );
}
