// Copyright 2017 Jesse B. Miller <jesse@jessebmiller.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// versionCmd represents the version command
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the client and contract version",
	Run: func(cmd *cobra.Command, args []string) {
		// print the version of the contract this project uses
		fmt.Println("version called")

		// print the version of this tool
		fmt.Println("0.0.0-not_implemented")
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
