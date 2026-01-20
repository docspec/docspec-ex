# Changelog

## 1.0.0 (2026-01-20)


### ⚠ BREAKING CHANGES

* API result changes
* rename package docspec to docspec_api

### Features

* bullet list item ([122189b](https://github.com/docspec/docspec-ex/commit/122189bcb26f889967324aea3bb6986be1f69ac1))
* extract unsupported nested blocks ([90ca7de](https://github.com/docspec/docspec-ex/commit/90ca7de6d448dbb7cc13ddf92e88714eeb7de699))
* fallback for DefinitionList, DefinitionTerm, DefinitionDetails ([c55e458](https://github.com/docspec/docspec-ex/commit/c55e4586ef1350b55582693f3cc2116298f8aed7))
* health endpoint ([6ac9ba7](https://github.com/docspec/docspec-ex/commit/6ac9ba737bc74f3f62770f296cc2256ef034754a))
* health endpoint ([70fb751](https://github.com/docspec/docspec-ex/commit/70fb751bb3b32fb281b231dca1d3e0b0ba76760b))
* image alt to caption ([89d3f6d](https://github.com/docspec/docspec-ex/commit/89d3f6d6952c8a624817dad9fba154cdc865e36b))
* images ([e42438e](https://github.com/docspec/docspec-ex/commit/e42438ed1f7e4418ccb20c78df9887046e01f9dd))
* initial DocSpec core library ([9fcae34](https://github.com/docspec/docspec-ex/commit/9fcae344657beb8471de4e15337981b05c3683b7))
* list continuation ([9643e0c](https://github.com/docspec/docspec-ex/commit/9643e0cb5a64a5a49db2debae93ba46b5b2ad2fd))
* list continuation ([049de54](https://github.com/docspec/docspec-ex/commit/049de54249058e4bf1e1c1a5f6bb3c3c9bf4999b))
* nested bullet list items ([6a22552](https://github.com/docspec/docspec-ex/commit/6a22552c60e852ded3665dc631240da51aaf8cd6))
* ordered list ([acfe78d](https://github.com/docspec/docspec-ex/commit/acfe78dbd8b5f5af6c972b1032faba75ab97780c))
* Rebrand project to DocSpec ([28130cb](https://github.com/docspec/docspec-ex/commit/28130cb2ebc66f6e098048b6e97207a95934845f))
* rename package docspec to docspec_api ([1be5bc6](https://github.com/docspec/docspec-ex/commit/1be5bc6d24429f129fd0fab746c7f36ea7a5e70f))
* return PartialBlock[] instead of document wrapper ([dd59ea3](https://github.com/docspec/docspec-ex/commit/dd59ea39e2f4e9a46fdc170087694ef0b334b602))
* support block quotes ([f29b40d](https://github.com/docspec/docspec-ex/commit/f29b40d88ac3dff346ef2465219ce998a449bb79))
* support external hyperlinks ([c4370f2](https://github.com/docspec/docspec-ex/commit/c4370f23a5757a0913a73a86cdf832aea50911ae))
* support for code blocks ([e15522d](https://github.com/docspec/docspec-ex/commit/e15522d0b0e38f5a9b51954a2a380c0be7e4f838))
* tables ([060d37c](https://github.com/docspec/docspec-ex/commit/060d37c88a4bfaff0d88e08d562633235d9ae121))
* text alignment ([271cb26](https://github.com/docspec/docspec-ex/commit/271cb2641399e4e0f1c2a4808d9f79c24781fae5))
* text alignment ([137fef5](https://github.com/docspec/docspec-ex/commit/137fef5227f8ebafeef00f182052e072969ef9cf))
* text background color ([9cac149](https://github.com/docspec/docspec-ex/commit/9cac149ca1ace4cb2e8cdbd7b9cbd6de35cb6341))
* text background color ([1d622ef](https://github.com/docspec/docspec-ex/commit/1d622efc55cb0b4a1d670da6812a3d7c84451765))


### Bug Fixes

* apk add unknown arguments in Dockerfile ([2c5399f](https://github.com/docspec/docspec-ex/commit/2c5399fdb70ae55b9b42871e4631e1542f826249))
* change message on 404 ([9b9b58a](https://github.com/docspec/docspec-ex/commit/9b9b58a53beb9ac656c4879903a16761c23d3140))
* conditionally include zip extra option for OTP &gt;= 27 ([f7fee36](https://github.com/docspec/docspec-ex/commit/f7fee36d03f4d50154376911831773e6614b5783))
* **deps:** bump bandit from 1.7.0 to 1.8.0 ([#8](https://github.com/docspec/docspec-ex/issues/8)) ([357d599](https://github.com/docspec/docspec-ex/commit/357d599dfa0ca9c5e86453974c6b5ac69e81e9a4))
* **deps:** bump logger_json from 7.0.3 to 7.0.4 ([#5](https://github.com/docspec/docspec-ex/issues/5)) ([5bf9a45](https://github.com/docspec/docspec-ex/commit/5bf9a4515cbdd8d4a625dc6d2fd5ee7ab27f01a9))
* **deps:** bump nldoc_spec from 3.1.5 to 3.1.10 ([#6](https://github.com/docspec/docspec-ex/issues/6)) ([ab22f27](https://github.com/docspec/docspec-ex/commit/ab22f27b0dd0aa85a202123cb1473fc00ced1518))
* **deps:** bump nldoc_util from 1.0.13 to 1.0.15 ([#7](https://github.com/docspec/docspec-ex/issues/7)) ([246d0d5](https://github.com/docspec/docspec-ex/commit/246d0d527b32ff8f5f9bebd2a0ebb499f07d5724))
* **deps:** update dependencies ([b5ab978](https://github.com/docspec/docspec-ex/commit/b5ab9785deeba4777ef54f013a03ac56a465ca8e))
* **deps:** update Elixir in build from 1.18 to 1.19 ([2a44446](https://github.com/docspec/docspec-ex/commit/2a444460410998db93cf7d3e5a5404da18e73e5d))
* **deps:** update Elixir in build from 1.18 to 1.19 ([30cb8c4](https://github.com/docspec/docspec-ex/commit/30cb8c4b1fa1a44c34bcaef008c2bb09d66de031))
* **deps:** update reader to enable alignment ([368bbf7](https://github.com/docspec/docspec-ex/commit/368bbf76d33c948f042724d415c32ecae07cc4e9))
* **deps:** update reader to enable alignment ([2e3572e](https://github.com/docspec/docspec-ex/commit/2e3572e0bcf25ed5f336db80e31f7925b409da1c))
* different colors for text and background ([441442d](https://github.com/docspec/docspec-ex/commit/441442dbd2a625ac794068169044f56ccb7adba3))
* disable dialyzer warnings_as_errors on OTP 25 ([4a929a8](https://github.com/docspec/docspec-ex/commit/4a929a8c9428f61a68faa5ffe7ccafdcb3948cae))
* do not convert images without any assets ([ca9d85a](https://github.com/docspec/docspec-ex/commit/ca9d85a7e6d38a5c1a3ce35486ccad249db80cf2))
* do not include component in version ([280d2eb](https://github.com/docspec/docspec-ex/commit/280d2eb9e5d045d20b726a3bec22b5041d9d5363))
* do not include component in version ([a5fa909](https://github.com/docspec/docspec-ex/commit/a5fa9091563a020b1f07ec4c8468ca667130e8fa))
* failure on empty row_colspans ([97c46e1](https://github.com/docspec/docspec-ex/commit/97c46e1be8796cb420e2f4eeb3cbcf8ad10e475c))
* improve extraction and support strict mode ([2c7949b](https://github.com/docspec/docspec-ex/commit/2c7949b7b483351e26638977585142ed2302a4c8))
* increase max heading level ([aac1300](https://github.com/docspec/docspec-ex/commit/aac1300c2e38ce3c1f6797ea71450fe472f74cc8))
* increase max heading level ([dd93c16](https://github.com/docspec/docspec-ex/commit/dd93c16c94bcf6d7d7ef9a2482c2a340313c086d))
* prevent tests jumping around ([71b38cd](https://github.com/docspec/docspec-ex/commit/71b38cd35956051af2b3e0328f016d4b0e6ffcc0))
* remove non-root user configuration that caused Kubernetes issues ([d972dff](https://github.com/docspec/docspec-ex/commit/d972dff4007814d9cf5d892fc1bcc9d83aafca5f))
* remove the blocknote conversion API from here ([2d9a030](https://github.com/docspec/docspec-ex/commit/2d9a030d29f16ca7d96cca8225dff0d6c0be6933))
* remove unused code ([fce5a0f](https://github.com/docspec/docspec-ex/commit/fce5a0f203324091a21f69093a44ecc700332c26))
* reversing ([b548077](https://github.com/docspec/docspec-ex/commit/b5480773699a8baa77633813986c502faa231a56))
* rowspan/colspan ([36cd084](https://github.com/docspec/docspec-ex/commit/36cd084efa8f8ef740f364f3481ceed6bfa6b8e8))
* run container as non-root user ([bc1be67](https://github.com/docspec/docspec-ex/commit/bc1be672c31cd1aeee889ba8a7f825fa1c282297))
* run container as non-root user for Kubernetes compliance ([349b678](https://github.com/docspec/docspec-ex/commit/349b678dbc673a38ec4af51b5e9cca6b5139961f))
* start of app ([9372926](https://github.com/docspec/docspec-ex/commit/9372926b63bba1930879c21f1018cef4acdc496c))
* start of app ([77ea626](https://github.com/docspec/docspec-ex/commit/77ea626b40aed1713c630d381ce7a63fd57fbbec))
* styling and write some tests ([0ba4c3b](https://github.com/docspec/docspec-ex/commit/0ba4c3b7a1963882fb4b33c397af25e1a259547a))
* table cell wrapping ([ee7b364](https://github.com/docspec/docspec-ex/commit/ee7b364f8817f92a8f25070cc08609ef20a7201a))
* table normalization, testing of spec, link content ([e353c8c](https://github.com/docspec/docspec-ex/commit/e353c8cd390c1af5f3dc661d53a5b1989986f6ab))
* table normalization, testing of spec, link content ([e27d4c6](https://github.com/docspec/docspec-ex/commit/e27d4c62e16055c41f52589772541cca8367be78))
* table spans ([ffaddab](https://github.com/docspec/docspec-ex/commit/ffaddaba858e0f14fe3110ddc68c54724b3dfdea))
* update dependencies ([4a65e56](https://github.com/docspec/docspec-ex/commit/4a65e56f77f8a94c0672ab915740abb30a501615))
* upload limit ([7c15749](https://github.com/docspec/docspec-ex/commit/7c15749b450c6302df87ccbc7cb7d12427efee05))
* use content instead of children and normalize inline to Text/Link ([37bf962](https://github.com/docspec/docspec-ex/commit/37bf962742403148f4b68f755a8271fe3bf0fdbd))
* use content instead of children and normalize inline to Text/Link ([ef4aaa3](https://github.com/docspec/docspec-ex/commit/ef4aaa3f14889bd26c1b28edc2d7f032ebd05314))
* values of text alignment ([7694a79](https://github.com/docspec/docspec-ex/commit/7694a7962b278e260f17826b8ad30c9bd48e1d5e))
* values of text alignment ([4f185e0](https://github.com/docspec/docspec-ex/commit/4f185e0e939aa781405e174d5c65279f1e847861))

## Changelog
